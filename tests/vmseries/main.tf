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
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

# Routes configured in test security VPC
module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

# Optinal S3 bucket for bootstrapping
module "bootstrap" {
  count              = var.use_s3_bucket_to_bootstrap ? 1 : 0
  source             = "../../modules/bootstrap"
  prefix             = local.bucket_name_prefix
  global_tags        = var.global_tags
  plugin-op-commands = var.plugin_op_commands
}

# VM-Series deployed for tests
module "vmseries" {
  for_each = var.vmseries
  source   = "../../modules/vmseries"

  name              = "${var.name_prefix}${random_string.random_sufix.id}${var.name_sufix}"
  ssh_key_name      = aws_key_pair.generated_key.key_name
  bootstrap_options = var.bootstrap_options
  vmseries_version  = var.vmseries_version
  interfaces = {
    for k, v in each.value.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.security_vpc.security_group_ids[v.security_group]], [])
      source_dest_check  = v.source_dest_check
      subnet_id          = module.security_subnet_sets[v.subnet].subnets[each.value.az].id
      create_public_ip   = v.create_public_ip
    }
  }

  tags = var.global_tags
}

locals {
  bucket_name_prefix = replace(var.name_prefix, "_", "-")
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
