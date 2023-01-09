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
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
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
}

# Random ID used in names of the resoruces created for tests
resource "random_id" "random_sufix" {
  byte_length = 8
}

# Test security VPC
module "security_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}${random_id.random_sufix.id}"
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

  name                = "${var.name_prefix}${random_id.random_sufix.id}_${each.key}"
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

  name         = "${var.name_prefix}${random_id.random_sufix.id}_${var.transit_gateway_name}"
  asn          = var.transit_gateway_asn
  route_tables = var.transit_gateway_route_tables
}

module "security_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = "${var.name_prefix}${random_id.random_sufix.id}_${var.security_vpc_tgw_attachment_name}"
  vpc_id                      = module.security_subnet_sets["tgw_attach"].vpc_id
  subnets                     = module.security_subnet_sets["tgw_attach"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["from_security_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["from_spoke_vpc"].id
  }
}
