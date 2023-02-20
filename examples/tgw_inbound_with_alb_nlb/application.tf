# ### APPLICATION INFRASTRUCTURE PART ### #
# Two VMs hosting a web server behind an internal Network Load Balancer.

locals {
  # Create custom routes for the Application VPC. In this example this is limited to only one route
  # that forces all non-local traffic to Transit Gateway. 
  # Keep in mind that this is a simple example with two VPCs only and it's meant to demonstrate inbound traffic only.
  # In case of a more complex architecture with more than one Application VPC and east-west traffic inspection,
  # one would have to add another route like below (this example assumes that the 2nd Application VPC
  # has the same layout as the 1st):
  #  [for cdir, subnet in var.app2_vpc_subnets :
  #    {
  #      subnet_key   = "appl"
  #      next_hop_set = module.app2_transit_gateway_attachment.next_hop_set
  #      to_cidr      = cdir
  #    } if subnet.set != "tgw"
  #  ]
  app_vpc_routes = concat(
    [for cdir, subnet in var.security_vpc_subnets :
      {
        subnet_key   = "appl" # specify to which subnet sets we will apply this rules
        next_hop_set = module.app_transit_gateway_attachment.next_hop_set
        to_cidr      = cdir
      } if subnet.set == "trust" # limit the target subnet sets only to trust set
    ]
  )

  # Internal Network Load Balancer rules set up. Please look at the explanation in `main.tf`.
  # Since the target are VMs with a single ENI `instance` type can be used.
  internal_app_nlb_rules = {
    for k, v in var.internal_app_nlb_rules : k => merge(v, {
      targets     = { for k, _ in var.app_vms : k => aws_instance.app_vm[k].id },
      target_type = "instance"
    })
  }
}

# ## APPLICATION NETWORK ## #
# Create Application VPC components.
module "app_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}${var.app_vpc_name}"
  cidr_block              = var.app_vpc_cidr
  security_groups         = var.app_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "app_subnet_sets" {
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.app_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.app_vpc.id
  has_secondary_cidrs = module.app_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.app_vpc_subnets : k => v if v.set == each.key }
}

module "app_vpc_routes" {
  for_each = { for route in local.app_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.app_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

module "app_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = "${var.name_prefix}${var.app_vpc_tgw_attachment_name}"
  vpc_id                      = module.app_subnet_sets["tgw"].vpc_id
  subnets                     = module.app_subnet_sets["tgw"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["spokes_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["security_vpc"].id
  }
}

# A custom static route assigned to the `spokes_vpc` Transit Gateway route table.
# It forces all traffic that is sent to the Transit Gateway from the Application VPC
# to be routed to the Transit Gateway Attachment in the Security VPC.
resource "aws_ec2_transit_gateway_route" "from_spokes_to_security" {
  transit_gateway_route_table_id = module.transit_gateway.route_tables["spokes_vpc"].id
  # Next hop.
  transit_gateway_attachment_id = module.security_transit_gateway_attachment.attachment.id
  # Default to inspect all packets coming through TGW route table from_spoke_vpc:
  destination_cidr_block = "0.0.0.0/0"
  blackhole              = false
}

# ## APPLICATION INFRASTRUCTURE ## #
# Create two Bitnami NGINX servers behind an Internal Network Load Balancer.
data "aws_ami" "bitnami" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.21*-linux-debian-10-x86_64-hvm-ebs-nami"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }
  owners = ["979382823631"] # bitnami = 979382823631
}

# Retrieve the default KMS key in the current region for EBS encryption
data "aws_ebs_default_kms_key" "current" {
  count = var.ebs_encrypted ? 1 : 0
}

resource "aws_instance" "app_vm" {
  for_each = var.app_vms

  ami           = data.aws_ami.bitnami.id
  instance_type = "t2.micro"
  tags          = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
  key_name      = var.ssh_key_name

  subnet_id              = module.app_subnet_sets["appl"].subnets[each.value.az].id
  vpc_security_group_ids = [module.app_vpc.security_group_ids["app_example"]]
  ebs_optimized          = true
  root_block_device {
    delete_on_termination = true
    encrypted             = var.ebs_encrypted
    kms_key_id            = var.ebs_encrypted == false ? null : data.aws_kms_alias.current_arn[0].target_key_arn
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

module "app_nlb" {
  source = "../../modules/nlb"

  name          = "${var.name_prefix}${var.internal_app_nlb_name}"
  internal_lb   = true
  subnets       = { for k, v in module.app_subnet_sets["appl"].subnets : k => { id = v.id } }
  vpc_id        = module.app_vpc.id
  balance_rules = local.internal_app_nlb_rules

  tags = var.global_tags
}
