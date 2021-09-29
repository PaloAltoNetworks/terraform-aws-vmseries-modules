# Description, just enough for a newcomer to be able to understand the reason why this code exist.
# And how to change the test when the main code changes.
#
# Core tests:
#   - Do the unknown inputs work? (Meaning the ones shown as `(known after apply)` in a Terraform Plan.)
#   - Can we consume the module output in a subsequent for_each?

data "aws_availability_zones" "this" {
  state = "available"
}

resource "random_pet" "this" {}

# The "u_" values are unknown during the `terraform plan`.
locals {
  u_true         = length(random_pet.this.id) > 0
  u_false        = length(random_pet.this.id) < 0
  u_string       = random_pet.this.id
  u_int          = length(random_pet.this.id)
  u_map          = merge({ (local.u_string) = local.u_string }, { (local.u_string) = local.u_string })
  u_sg_rule_type = local.u_true ? "egress" : "ingress"
}

### The code under test. ###

module "vpc" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = true
  security_groups = {
    sg = {
      rules = {
        r = {
          # Nested attributes that can handle unknown values.
          type = local.u_sg_rule_type
        }
      }
      # Nested attributes that can handle unknown values.
      name = local.u_string
    }
  }
  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "vpc_noigw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = false # the change
  security_groups = {
    sg = {
      rules = {
        r = {
          # Nested attributes that can handle unknown values.
          type = local.u_sg_rule_type
        }
      }
      # Nested attributes that can handle unknown values.
      name = local.u_string
    }
  }
  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "novpc_igw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = false
  create_internet_gateway = true # the change
  # Inputs that can handle unknown values.
  name                             = module.vpc.name
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "novpc_noigw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = false # the change
  create_internet_gateway = false
  use_internet_gateway    = true
  # Inputs that can handle unknown values.
  name                             = module.vpc.name
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "novpc_noigw_nouse" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = false
  create_internet_gateway = false
  use_internet_gateway    = false # the change
  # Inputs that can handle unknown values.
  name                             = module.vpc.name
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "vpc_vgw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = true
  create_vpn_gateway      = true # the change
  security_groups = {
    sg = {
      rules = {
        r = {
          # Nested attributes that can handle unknown values.
          type = local.u_sg_rule_type
        }
      }
      # Nested attributes that can handle unknown values.
      name = local.u_string
    }
  }
  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "vpc_vgw_noigw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = false # the change
  create_vpn_gateway      = true
  security_groups = {
    sg = {
      rules = {
        r = {
          # Nested attributes that can handle unknown values.
          type = local.u_sg_rule_type
        }
      }
      # Nested attributes that can handle unknown values.
      name = local.u_string
    }
  }
  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "novpc_igw_vgw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = false # the change
  create_internet_gateway = true
  create_vpn_gateway      = true
  # Inputs that can handle unknown values.
  name                             = module.vpc.name
  enable_dns_hostnames             = local.u_true
  enable_dns_support               = local.u_true
  assign_generated_ipv6_cidr_block = local.u_true
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_int
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

################ Consumption #######################################################
#
# For all module calls under test feed the map outputs to a dummy for_each.
# The Plan will immediately test whether an output is for_each-compatible,
# there is no need to run the entire `terraform apply`.

# TODO: Invalid for_each argument:  module.vpc.ipv6_routing_cidrs

# module.vpc

resource "random_pet" "consume_vpc_routing_cidrs" {
  for_each = module.vpc.routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_vpc_security_group_ids" {
  for_each = module.vpc.security_group_ids

  prefix = each.key
}

# module.vpc_noigw

resource "random_pet" "consume_vpc_noigw_routing_cidrs" {
  for_each = module.vpc_noigw.routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_vpc_noigw_security_group_ids" {
  for_each = module.vpc_noigw.security_group_ids

  prefix = each.key
}

# module.novpc_igw

resource "random_pet" "consume_novpc_igw_routing_cidrs" {
  for_each = module.novpc_igw.routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_novpc_igw_security_group_ids" {
  for_each = module.novpc_igw.security_group_ids

  prefix = each.key
}

# module.novpc_noigw_nouse

resource "random_pet" "consume_novpc_noigw_nouse_routing_cidrs" {
  for_each = module.novpc_noigw_nouse.routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_novpc_noigw_nouse_security_group_ids" {
  for_each = module.novpc_noigw_nouse.security_group_ids

  prefix = each.key
}

# module.novpc_noigw

resource "random_pet" "consume_novpc_noigw_routing_cidrs" {
  for_each = module.novpc_noigw.routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_novpc_noigw_security_group_ids" {
  for_each = module.novpc_noigw.security_group_ids

  prefix = each.key
}

# module.vpc_vgw

resource "random_pet" "consume_vpc_vgw_routing_cidrs" {
  for_each = module.vpc_vgw.routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_vpc_vgw_security_group_ids" {
  for_each = module.vpc_vgw.security_group_ids

  prefix = each.key
}

resource "random_pet" "consume_vpc_vgw_maps" {
  for_each = merge(
    module.vpc_vgw.routing_cidrs,
    module.vpc_vgw.security_group_ids,
  )

  prefix = each.key
}

resource "random_pet" "consume_vpc_vgw_bools" {
  count = contains([
    true,
    # local.u_true,
    true,
  ], false) ? 1 : 0
}

# module.vpc_vgw_noigw

# module.novpc_igw_vgw

resource "random_pet" "consume_maps" {
  for_each = merge(
    module.vpc_vgw.routing_cidrs,
    module.vpc_vgw.security_group_ids,

    module.vpc_vgw_noigw.routing_cidrs,
    module.vpc_vgw_noigw.security_group_ids,

    module.novpc_igw_vgw.routing_cidrs,
    module.novpc_igw_vgw.security_group_ids,
  )
}
