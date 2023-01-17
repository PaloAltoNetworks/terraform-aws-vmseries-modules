locals {
  # List of VPC routes
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_app_routes :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_transit_gateway_attachment[0].next_hop_set
        to_cidr      = cidr
      } if length(var.transit_gateway_route_tables) > 0
    ],
  )
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
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids        = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr                = try(each.value.to_cidr, null)
  destination_type       = try(each.value.destination_type, "ipv4")
  managed_prefix_list_id = try(each.value.managed_prefix_list_id, null)
  next_hop_set           = each.value.next_hop_set
}

# Transit gateway (without attachments)
module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name         = var.transit_gateway_name != null ? "${var.name_prefix}${random_string.random_sufix.id}_${var.transit_gateway_name}" : null
  asn          = var.transit_gateway_asn
  route_tables = var.transit_gateway_route_tables
}

# Transit gateway attachment for security VPC
module "security_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"
  count  = length(var.transit_gateway_route_tables) > 0 ? 1 : 0

  name                        = "${var.name_prefix}${random_string.random_sufix.id}_${var.security_vpc_tgw_attachment_name}"
  vpc_id                      = module.security_subnet_sets["tgw_attach"].vpc_id
  subnets                     = module.security_subnet_sets["tgw_attach"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["from_security_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["from_spoke_vpc"].id
  }
}
