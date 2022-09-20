module "bootstrap" {
  source                 = "../../modules/bootstrap"
  prefix                 = var.name_prefix
  global_tags            = var.global_tags
  create_iam_role_policy = var.create_iam_role_policy
  iam_role_name          = var.iam_role_name
  source_root_directory  = var.source_root_directory
}

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
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

module "vmseries" {
  for_each = var.vmseries
  source   = "../../modules/vmseries"

  name             = "${var.name_prefix}vmseries"
  vmseries_version = var.vmseries_version
  interfaces = {
    for k, v in each.value.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.security_vpc.security_group_ids[v.security_group]], [])
      source_dest_check  = v.source_dest_check
      subnet_id          = module.security_subnet_sets[v.subnet].subnets[each.value.az].id
      create_public_ip   = v.create_public_ip
    }
  }

  bootstrap_options = join(";", compact(concat(
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap.bucket_name}"],
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  )))
  # bootstrap_options = "plugin-op-commands=aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable;type=dhcp-client;hostname=sbvms01"

  iam_instance_profile = module.bootstrap.instance_profile_name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
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
  )
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}
