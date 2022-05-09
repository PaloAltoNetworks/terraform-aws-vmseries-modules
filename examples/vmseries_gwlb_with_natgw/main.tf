module "security_vpc" {
  source = "../../modules/vpc"

  name                    = var.security_vpc_name
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "security_subnet_sets" {
  # The "set" here means we will repeat in each AZ an identical/similar subnet.
  # The notion of "set" is used a lot here, it extends to routes, routes' next hops,
  # gwlb endpoints and any other resources which would be a single point of failure when placed
  # in a single AZ.
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
  source = "../../modules/nat_gateway_set"

  subnets = module.security_subnet_sets["natgw"].subnets
}

# Gateway Load Balancer
module "security_gwlb" {
  source = "../../modules/gwlb"

  name    = var.gwlb_name
  vpc_id  = module.security_subnet_sets["gwlb"].vpc_id
  subnets = module.security_subnet_sets["gwlb"].subnets

  target_instances = module.vmseries.firewalls
}

# Gateway Load Balancer Endpoints
module "gwlbe_outbound" {
  source = "../../modules/gwlb_endpoint_set"

  name              = var.gwlb_endpoint_set_outbound_name
  gwlb_service_name = module.security_gwlb.endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_outbound"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_outbound"].subnets
}

# VM-Series
module "vmseries" {
  source = "../../modules/vmseries"

  ami_id     = var.ami_id
  region     = var.region
  interfaces = var.interfaces
  firewalls = [
    {
      name    = "vmseries01"
      fw_tags = {}
      bootstrap_options = {
        mgmt-interface-swap = "enable"
        plugin-op-commands  = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        type                = "dhcp-client"
        hostname            = "vmseries01"
        tplname             = ""
        dgname              = ""
        panorama-server     = "10.177.67.70"
        panorama-server-2   = ""
        vm-auth-key         = ""
        authcodes           = ""
        op-command-modes    = ""
      }
      interfaces = [
        { name = "vmseries01_data", index = "0" },
        { name = "vmseries01_mgmt", index = "1" },
        { name = "vmseries01_untrust", index = "2" },
      ]
    },
    {
      name    = "vmseries02"
      fw_tags = {}
      bootstrap_options = {
        mgmt-interface-swap = "enable"
        plugin-op-commands  = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        type                = "dhcp-client"
        hostname            = "vmseries02"
        tplname             = ""
        dgname              = ""
        panorama-server     = "10.177.67.70"
        panorama-server-2   = ""
        vm-auth-key         = ""
        authcodes           = ""
        op-command-modes    = ""
      }
      interfaces = [
        { name = "vmseries02_data", index = "0" },
        { name = "vmseries02_mgmt", index = "1" },
        { name = "vmseries02_untrust", index = "2" },
      ]
    }
  ]
  security_groups_map = module.security_vpc.security_group_ids
  prefix_name_tag     = var.prefix_name_tag
  tags                = var.global_tags
  ssh_key_name        = var.ssh_key_name
  fw_instance_type    = var.fw_instance_type

  subnets_map = { for v in flatten([for _, set in module.security_subnet_sets :
    [for az, subnet in set.subnets :
      {
        subnet_name = set.subnet_names[az]
        subnet_id   = subnet.id
      }
    ]
  ]) : v.subnet_name => v.subnet_id }
}

locals {
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "untrust" //public interface
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "mgmt" //management interface
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_mgmt_routes_to_tgw :
      {
        subnet_key   = "mgmt" //management interface
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "tgw_attach" //transit gateway attachments
        next_hop_set = module.gwlbe_outbound.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_mgmt_routes_to_tgw :
      {
        subnet_key   = "tgw_attach" //transit gateway attachments
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "gwlbe_outbound" //gwlb endpoint
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
  )
}

# Security VPC Routes
module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}
