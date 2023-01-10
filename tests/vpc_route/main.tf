locals {
  # List of VPC routes created to check every type of destination and next hop
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_mgmt_routes_to_igw :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [
      {
        subnet_key             = "mgmt"
        next_hop_set           = module.security_vpc.igw_as_next_hop_set
        destination_type       = "mpl"
        managed_prefix_list_id = aws_ec2_managed_prefix_list.this.id
      }
    ],
    [for cidr in var.security_vpc_app_routes_to_tgw :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_transit_gateway_attachment[0].next_hop_set
        to_cidr      = cidr
      } if var.transit_gateway_create
    ],
    [for cidr in var.security_vpc_app_routes_to_natgw :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.natgw_set[0].next_hop_set
        to_cidr      = cidr
      } if var.nat_gateway_create
    ],
    [for cidr in var.security_vpc_app_routes_to_gwlb :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_gwlb_endpoint_set[0].next_hop_set
        to_cidr      = cidr
      } if var.gwlb_create
    ],
  )

  # Object used while creating managed prefix list
  managed_prefix_list = {
    name        = "${var.name_prefix}mgmt"
    max_entries = 10
    entries = {
      for cidr in concat(var.security_vpc_mgmt_routes_to_igw, var.security_vpc_app_routes_to_igw) : cidr => {
        cidr        = cidr
        description = "CIDR in managed prefix list for MGMT"
      }
    }
  }

  # Object used while creating NAT gateway
  nat_gateway_names = {
    "us-east-1a" = "${var.name_prefix}${random_string.random_sufix.id}_natgw"
  }
}

# Random ID used in names of the resoruces created for tests
resource "random_string" "random_sufix" {
  length  = 16
  special = false
}

# Test security VPC
module "security_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}${random_string.random_sufix.id}"
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

# Subnets configured in test security VPC
module "security_subnet_sets" {
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = "${var.name_prefix}${random_string.random_sufix.id}_${each.key}"
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

# Routes configured in test security VPC
module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${try(route.to_cidr, local.managed_prefix_list.name)}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids        = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr                = try(each.value.to_cidr, null)
  destination_type       = try(each.value.destination_type, "ipv4")
  managed_prefix_list_id = try(each.value.managed_prefix_list_id, null)
  next_hop_set           = each.value.next_hop_set
}

# Managed prefix lists used as destination in one of the configured VPC routes
resource "aws_ec2_managed_prefix_list" "this" {
  name           = local.managed_prefix_list.name
  address_family = "IPv4"
  max_entries    = local.managed_prefix_list.max_entries

  dynamic "entry" {
    for_each = local.managed_prefix_list.entries
    content {
      cidr        = entry.value["cidr"]
      description = entry.value["description"]
    }
  }
}

# Transit gateway and its attachments. TGW is used in one othe the configured VPC routes as next hop
module "transit_gateway" {
  source = "../../modules/transit_gateway"
  count  = var.transit_gateway_create ? 1 : 0

  name         = "${var.name_prefix}${random_string.random_sufix.id}_${var.transit_gateway_name}"
  asn          = var.transit_gateway_asn
  route_tables = var.transit_gateway_route_tables
}

module "security_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"
  count  = var.transit_gateway_create ? 1 : 0

  name                        = "${var.name_prefix}${random_string.random_sufix.id}_${var.security_vpc_tgw_attachment_name}"
  vpc_id                      = module.security_subnet_sets["tgw_attach"].vpc_id
  subnets                     = module.security_subnet_sets["tgw_attach"].subnets
  transit_gateway_route_table = module.transit_gateway[0].route_tables["from_security_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway[0].route_tables["from_spoke_vpc"].id
  }
}

# NAT gateway used in one othe the configured VPC routes as next hop
module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
  source = "../../modules/nat_gateway_set"
  count  = var.nat_gateway_create ? 1 : 0

  nat_gateway_names = local.nat_gateway_names
  subnets           = module.security_subnet_sets["natgw"].subnets
}

# GWLB and endpoint used in one othe the configured VPC routes as next hop
module "security_gwlb" {
  source = "../../modules/gwlb"
  count  = var.gwlb_create ? 1 : 0

  name    = "${random_string.random_sufix.id}-${var.gwlb_name}"
  vpc_id  = module.security_subnet_sets["gwlb"].vpc_id
  subnets = module.security_subnet_sets["gwlb"].subnets

  target_instances = {}
}

module "security_gwlb_endpoint_set" {
  source = "../../modules/gwlb_endpoint_set"
  count  = var.gwlb_create ? 1 : 0

  name              = "${var.name_prefix}${random_string.random_sufix.id}_${var.gwlb_endpoint_set_inbound_name}"
  gwlb_service_name = module.security_gwlb[0].endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_inbound"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_inbound"].subnets
}
