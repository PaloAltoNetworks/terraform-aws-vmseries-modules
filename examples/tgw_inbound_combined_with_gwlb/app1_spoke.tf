module "app1_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}${var.app1_vpc_name}"
  cidr_block              = var.app1_vpc_cidr
  security_groups         = var.app1_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "app1_subnet_sets" {
  for_each = toset(distinct([for _, v in var.app1_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.app1_vpc.id
  has_secondary_cidrs = module.app1_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.app1_vpc_subnets : k => v if v.set == each.key }
}

module "app1_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = var.app1_transit_gateway_attachment_name
  vpc_id                      = module.app1_subnet_sets["app1_vm"].vpc_id
  subnets                     = module.app1_subnet_sets["app1_vm"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["from_spoke_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["from_security_vpc"].id
  }
}

module "app1_gwlbe_inbound" {
  source = "../../modules/gwlb_endpoint_set"

  name              = var.app1_gwlb_endpoint_set_name
  gwlb_service_name = coalesce(var.security_gwlb_service_name, module.security_gwlb.endpoint_service.service_name) # this is cross-vpc
  vpc_id            = module.app1_subnet_sets["app1_gwlbe"].vpc_id
  subnets           = module.app1_subnet_sets["app1_gwlbe"].subnets
  act_as_next_hop_for = {
    "from-igw-to-lb" = {
      route_table_id = module.app1_vpc.internet_gateway_route_table.id
      to_subnets     = module.app1_subnet_sets["app1_lb"].subnets
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table,
    # and AWS allows their destinations to only be:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table
  }
}

module "app1_route" {
  for_each = {
    from-gwlbe-to-igw = {
      next_hop_set    = module.app1_vpc.igw_as_next_hop_set
      route_table_ids = module.app1_subnet_sets["app1_gwlbe"].unique_route_table_ids
      to_cidr         = "0.0.0.0/0"
    }
    from-web-to-tgw = {
      next_hop_set    = module.app1_transit_gateway_attachment.next_hop_set
      route_table_ids = module.app1_subnet_sets["app1_vm"].unique_route_table_ids
      to_cidr         = "0.0.0.0/0"
    }
    from-lb-to-gwlbe = {
      next_hop_set    = module.app1_gwlbe_inbound.next_hop_set
      route_table_ids = module.app1_subnet_sets["app1_lb"].unique_route_table_ids
      to_cidr         = "0.0.0.0/0"
    }
  }
  source = "../../modules/vpc_route"

  route_table_ids = each.value.route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

### App1 EC2 instance ###

data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.21*-linux-debian-10-x86_64-hvm-ebs-nami"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  owners = ["979382823631"] # bitnami = 979382823631
}

resource "aws_instance" "app1_vm" {
  for_each = var.app1_vms

  ami                    = data.aws_ami.this.id
  instance_type          = var.app1_vm_type
  key_name               = var.ssh_key_name
  subnet_id              = module.app1_subnet_sets["app1_vm"].subnets[each.value.az].id
  vpc_security_group_ids = [module.app1_vpc.security_group_ids["app1_vm"]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}


### Inbound Internal Load Balancer ###

module "app1_lb" {
  source = "../../modules/nlb"

  name        = "${var.name_prefix}app1-lb"
  internal_lb = true
  subnets     = { for k, v in module.app1_subnet_sets["app1_lb"].subnets : k => { id = v.id } }
  vpc_id      = module.app1_subnet_sets["app1_lb"].vpc_id

  balance_rules = {
    "SSH-traffic" = {
      protocol    = "TCP"
      port        = "22"
      target_type = "instance"
      stickiness  = true
      targets     = { for k, v in var.app1_vms : k => aws_instance.app1_vm[k].id }
    }
    "HTTP-traffic" = {
      protocol    = "TCP"
      port        = "80"
      target_type = "instance"
      stickiness  = false
      targets     = { for k, v in var.app1_vms : k => aws_instance.app1_vm[k].id }
    }
    "HTTPS-traffic" = {
      protocol    = "TCP"
      port        = "443"
      target_type = "instance"
      stickiness  = false
      targets     = { for k, v in var.app1_vms : k => aws_instance.app1_vm[k].id }
    }
  }

  tags = var.global_tags
}
