locals {
  security_vpc_routes = concat(
    ### For testing purposes always next hop is IGW to limit time and costs of creating
    ### different types of next hops like TGW or GWLB endpoints.
    ### The purpose of the test is to check creating managed prefix list, not
    ### veryfing different types of next hop.
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
  )

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

resource "random_id" "random_sufix" {
  byte_length = 8
}

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

module "security_subnet_sets" {
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

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

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${try(route.to_cidr, local.managed_prefix_list.name)}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids        = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr                = try(each.value.to_cidr, null)
  destination_type       = try(each.value.destination_type, "ipv4")
  managed_prefix_list_id = try(each.value.managed_prefix_list_id, null)
  next_hop_set           = each.value.next_hop_set
}
