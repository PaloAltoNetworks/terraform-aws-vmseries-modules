module "security_vpc" {
  source = "../../modules/vpc"

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

locals {
  security_vpc_routes = concat(
    [
      for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "lambda"
        next_hop_set = module.natgw_set.next_hop_set
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
  )
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

module "natgw_set" {
  source = "../../modules/nat_gateway_set"

  subnets = module.security_subnet_sets["natgw"].subnets
}

module "vm_series_asg" {
  source = "../../modules/asg"

  ssh_key_name      = var.ssh_key_name
  name_prefix       = var.name_prefix
  global_tags       = var.global_tags
  bootstrap_options = var.bootstrap_options
  vmseries_version  = var.vmseries_version
  max_size          = var.asg_max_size
  min_size          = var.asg_min_size
  desired_capacity  = var.asg_desired_cap
  interfaces = {
    for k, v in var.vmseries_interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.security_vpc.security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = { for z, c in v.subnet : c => module.security_subnet_sets[k].subnets[c].id }
      create_public_ip   = try(v.create_public_ip, false)
    }
  }
  subnet_ids         = [for k, v in var.vpc_subnets : module.security_subnet_sets[v.set].subnets[v.az].id if v.set == "lambda"]
  security_group_ids = [module.security_vpc.security_group_ids["lambda"]]
}
