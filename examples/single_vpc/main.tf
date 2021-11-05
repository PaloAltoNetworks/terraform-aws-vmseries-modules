locals {
  ssh_key_name = var.create_ssh_key ? aws_key_pair.this[0].key_name : var.ssh_key_name
}

resource "aws_key_pair" "this" {
  count = var.create_ssh_key ? 1 : 0

  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_file_path)
  tags       = var.global_tags
}

module "vpc" {
  source = "../../modules/vpc"

  name                    = "${var.prefix_name_tag}vpc"
  cidr_block              = var.vpc_cidr_block
  secondary_cidr_blocks   = var.vpc_secondary_cidr_blocks
  create_internet_gateway = true
  global_tags             = var.global_tags
  vpc_tags                = var.vpc_tags
  security_groups         = var.security_groups
}

module "subnet_sets" {
  # The "set" here means we will repeat in each AZ an identical/similar subnet.
  # The notion of "set" is used a lot here, it extends to nat gateways, routes, routes' next hops,
  # gwlb endpoints and any other resources which would be a single point of failure when placed
  # in a single AZ.
  for_each = toset(distinct([for _, v in var.subnets : v.set]))
  source   = "../../modules/subnet_set"

  name   = each.key
  cidrs  = { for k, v in var.subnets : k => v if v.set == each.key }
  vpc_id = module.vpc.id
}

module "nat_gateway_set" {
  source = "../../modules/nat_gateway_set"

  subnet_set = module.subnet_sets["natgw-1"]
}

module "vpc_route" {
  for_each = {
    mgmt = {
      route_table_ids = module.subnet_sets["mgmt-1"].unique_route_table_ids
      next_hop_set    = module.vpc.igw_as_next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
    public = {
      route_table_ids = module.subnet_sets["public-1"].unique_route_table_ids
      next_hop_set    = module.nat_gateway_set.next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
    natgw = {
      route_table_ids = module.subnet_sets["natgw-1"].unique_route_table_ids
      next_hop_set    = module.vpc.igw_as_next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
  }
  source = "../../modules/vpc_route"

  route_table_ids = each.value.route_table_ids
  next_hop_set    = each.value.next_hop_set
  to_cidr         = each.value.to_cidr
}

module "vmseries" {
  source = "../../modules/vmseries"

  region               = var.region
  security_groups_map  = module.vpc.security_group_ids
  prefix_name_tag      = var.prefix_name_tag
  interfaces           = var.interfaces
  addtional_interfaces = var.addtional_interfaces
  tags                 = var.global_tags
  ssh_key_name         = var.ssh_key_name
  firewalls            = var.firewalls
  fw_license_type      = var.fw_license_type
  fw_version           = var.fw_version
  fw_instance_type     = var.fw_instance_type

  # Because vmseries module does not yet handle subnet_set,
  # convert to a backward compatible map.
  subnets_map = { for v in flatten([for _, set in module.subnet_sets :
    [for _, subnet in set.subnets :
      {
        subnet = subnet
      }
    ]
  ]) : v.subnet.tags.Name => v.subnet.id }
}
