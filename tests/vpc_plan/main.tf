# Test the behavior of unknown values in module's inputs and outputs.
# See https://github.com/PaloAltoNetworks/terraform-best-practices/blob/91c6481de8a470390dd04a1286eb0f2e6cabcc3f/tests.md#the-unknown-value-pitfall
#
# This test needs an update when adding/removing any inputs.
# This test needs an update when adding/removing selected outputs (specifically map outputs).

resource "random_pet" "this" {}

# The "u_" values are unknown during the `terraform plan`.
locals {
  u_bool   = length(random_pet.this.id) > 0
  u_string = random_pet.this.id
  u_number = length(random_pet.this.id)
  u_map = merge(
    { (local.u_string) = local.u_string },
    { knownkey = "knownvalue" },
    # It is unknown whether the merge is a single-element map or a two-element map.
  )
  u_sg_rule_type = local.u_bool ? "egress" : "ingress"

  # Just for brevity:
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
}

### The code under test. ###

module "vpc" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = true
  create_vpn_gateway      = true
  security_groups         = local.security_groups

  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

# More more variants of the same call.
# Above we had all the possible "create" flags to true, for the most complex case.
# Below replace each "true" with "false", one by one. It should detect unwanted dependencies.

module "vpc_novgw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = true
  create_vpn_gateway      = false # the change
  security_groups         = local.security_groups

  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
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
  use_internet_gateway    = false # the change
  create_vpn_gateway      = true
  security_groups         = local.security_groups

  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "vpc_useigw" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = false
  use_internet_gateway    = true # the change
  create_vpn_gateway      = true
  security_groups         = local.security_groups

  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "novpc" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = false # the change
  create_internet_gateway = true
  create_vpn_gateway      = true
  security_groups         = local.security_groups

  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

# For the known values that are lists or maps, check if they can be empty, one by one.

module "vpc_nosg" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = ["10.0.1.0/24", "10.0.2.0/24"]
  create_internet_gateway = true
  create_vpn_gateway      = true
  security_groups         = {} # the change

  # Inputs that can handle unknown values.
  name                             = local.u_string
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

module "vpc_nosecond" {
  source = "../../modules/vpc"

  # Inputs that cannot handle unknown values.
  create_vpc              = true
  cidr_block              = "10.0.0.0/24"
  secondary_cidr_blocks   = [] # the change
  create_internet_gateway = true
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
  enable_dns_hostnames             = local.u_bool
  enable_dns_support               = local.u_bool
  assign_generated_ipv6_cidr_block = local.u_bool
  instance_tenancy                 = local.u_string
  vpn_gateway_amazon_side_asn      = local.u_number
  global_tags                      = local.u_map
  vpc_tags                         = local.u_map
}

################ Consumption of Outputs ######################################################
#
# There is no need and no intention to run `terraform apply` on this. This code is only
# concerned with `terraform plan` succeeding.
#
# For all module calls under test, feed the map outputs to a dummy for_each.
# The Plan succeeds only if every argument to the `for_each = merge(...)` is for_each-compatible,
# otherwise it fails immediately with "Invalid for_each argument".

resource "random_pet" "consume_maps" {
  for_each = merge(
    module.vpc.routing_cidrs,
    module.vpc.security_group_ids,

    module.vpc_nosg.routing_cidrs,
    module.vpc_nosg.security_group_ids,

    module.vpc_nosecond.routing_cidrs,
    module.vpc_nosecond.security_group_ids,

    module.vpc_noigw.routing_cidrs,
    module.vpc_noigw.security_group_ids,

    module.vpc_useigw.routing_cidrs,
    module.vpc_useigw.security_group_ids,

    module.vpc_novgw.routing_cidrs,
    module.vpc_novgw.security_group_ids,

    module.novpc.routing_cidrs,
    module.novpc.security_group_ids,
  )
}
