#launch vm series 
#https://docs.paloaltonetworks.com/vm-series/9-1/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/launch-the-vm-series-firewall-on-aws

#Generate auth key 
#https://docs.paloaltonetworks.com/vm-series/11-0/vm-series-deployment/bootstrap-the-vm-series-firewall/generate-the-vm-auth-key-on-panorama

#Get device certificate
#https://docs.paloaltonetworks.com/panorama/9-1/panorama-admin/set-up-panorama/install-the-panorama-device-certificate

#recover connectivity to panorama
#https://docs.paloaltonetworks.com/panorama/10-1/panorama-admin/troubleshooting/recover-managed-device-connectivity-to-panorama

#Tshooting panorama connectivty
#https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000ClaWCAS

#Validate bootstrapping
#https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-the-vm-series-firewall-in-aws

module "security_vpc" {
  source                  = "../../modules/vpc"
  create_vpc              = true
  name                    = var.vpc_name
  cidr_block              = var.vpc_cidr
  security_groups         = var.vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "security_subnet_sets" {
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.vpc_subnets : k => v if v.set == each.key }
}


### NATGW ###

module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
  source = "../../modules/nat_gateway_set"

  subnets = module.security_subnet_sets["natgw"].subnets
}


### TGW ###

module "transit_gateway" {
  source = "../../modules/transit_gateway"
  create = false
  id     = var.transit_gateway_id
  # name         = "${var.name_prefix}${var.transit_gateway_name}"
  # asn          = var.transit_gateway_asn
  route_tables = var.transit_gateway_route_tables
}

module "security_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = "${var.name_prefix}${var.security_vpc_tgw_attachment_name}"
  vpc_id                      = module.security_subnet_sets["tgw_attach"].vpc_id
  subnets                     = module.security_subnet_sets["tgw_attach"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["from_security_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["from_spoke_vpc"].id
  }
}

resource "aws_ec2_transit_gateway_route" "from_spokes_to_security" {
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_spoke_vpc"].id
  # Next hop.
  transit_gateway_attachment_id = module.security_transit_gateway_attachment.attachment.id
  # Default to inspect all packets coming through TGW route table from_spoke_vpc:
  destination_cidr_block = "0.0.0.0/0"
  blackhole              = false
}


### GWLB ###

module "security_gwlb" {
  source = "../../modules/gwlb"

  name    = "${var.name_prefix}${var.gwlb_name}"
  vpc_id  = module.security_subnet_sets["gwlb"].vpc_id
  subnets = module.security_subnet_sets["gwlb"].subnets

  #target instance --> ASG
  #target_instances = { for k, v in module.vmseries : k => { id = v.instance.id } }

}

module "gwlbe_eastwest" {
  source = "../../modules/gwlb_endpoint_set"

  name              = "${var.name_prefix}${var.gwlb_endpoint_set_eastwest_name}"
  gwlb_service_name = module.security_gwlb.endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_eastwest"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_eastwest"].subnets
}

module "gwlbe_outbound" {
  source = "../../modules/gwlb_endpoint_set"

  name              = "${var.name_prefix}${var.gwlb_endpoint_set_outbound_name}"
  gwlb_service_name = module.security_gwlb.endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_outbound"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_outbound"].subnets
}

locals {
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in concat(var.security_vpc_routes_eastwest_cidrs, var.security_vpc_mgmt_routes_to_tgw) :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_eastwest_cidrs :
      {
        subnet_key   = "tgw_attach"
        next_hop_set = module.gwlbe_eastwest.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "tgw_attach"
        next_hop_set = module.gwlbe_outbound.next_hop_set
        to_cidr      = cidr
      }
    ],

    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "gwlbe_outbound"
        next_hop_set = module.natgw_set.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_source_cidrs :
      {
        subnet_key   = "gwlbe_outbound"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_eastwest_cidrs :
      {
        subnet_key   = "gwlbe_eastwest"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "natgw"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_source_cidrs :
      {
        subnet_key   = "natgw"
        next_hop_set = module.gwlbe_outbound.next_hop_set
        to_cidr      = cidr
      }
    ],
  )
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

resource "aws_key_pair" "this" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
  tags       = var.global_tags
}


module "vm_series_asg" {
  source            = "../../modules/asg"
  instance_type     = var.asg_instance_type
  target_group_arns = [module.security_gwlb.target_group.arn]
  ssh_key_name      = var.ssh_key_name
  name_prefix       = var.name_prefix
  global_tags       = var.global_tags
  bootstrap_options = var.bootstrap_options
  vmseries_version  = var.vmseries_version
  max_size          = var.asg_max_size
  min_size          = var.asg_min_size
  desired_capacity  = var.asg_desired_cap

  interfaces = {
    for interface, options in var.vmseries_interfaces : interface => {
      device_index       = options.device_index
      security_group_ids = try([module.security_vpc.security_group_ids[options.security_group]], [])
      source_dest_check  = try(options.source_dest_check, false)
      subnet_id = { for az, setname in options.subnet :

        az => module.security_subnet_sets[setname].subnets[az].id

      }
      create_public_ip = try(options.create_public_ip, false)
    }
  }
}
