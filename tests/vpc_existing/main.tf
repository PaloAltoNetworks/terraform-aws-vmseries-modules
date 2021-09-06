# Description, just enough for a newcomer to be able to understand the reason why this code exist.
# And how to change the test when the main code changes.
#
# Core tests:
#   - Do the dynamic inputs work? (Dynamic here means "unknown until Terraform's apply stage".)
#   - Can we discover the pre-existing subnets and their pre-existing route tables?
#   - Can we create a shared route table?
#   - Can we discover a pre-existing shared route table?
#
# Boilerplate tests:
#   - Can we call each module twice?
#   - Can we consume the module output in a subsequent for_each?

variable "switchme" {}

data "aws_availability_zones" "this" {
  state = "available"
}

resource "random_pet" "this" {}

# The values that are unknown until the Terraform's apply phase runs.
locals {
  dyn_true   = length(random_pet.this.id) > 0
  dyn_false  = length(random_pet.this.id) < 0
  dyn_rtname = "test4-rt-${random_pet.this.id}"
  dyn_s1name = "test4-s1-${random_pet.this.id}"
  dyn_s2name = "test4-s2-${random_pet.this.id}"
  dyn_az_a   = data.aws_availability_zones.this.names[0]
  dyn_az_b   = data.aws_availability_zones.this.names[1]
}

# The inputs are also tangled to the apply phase.
locals {
  dyn_input_switch = (local.dyn_true == var.switchme)
}

locals {
  vpcname = "test4-vpc"
  subnets_main = {
    "10.0.10.0/24" = { az = local.dyn_az_a, set = "my" }
    "10.5.20.0/24" = { az = local.dyn_az_b, set = "my" }
    "10.5.30.0/24" = { az = local.dyn_az_a, set = "second", route_table_name = local.dyn_rtname } # TODO no need for a shared route if we test it in the tgw_existing or similar
    "10.0.40.0/24" = { az = local.dyn_az_b, set = "second", route_table_name = local.dyn_rtname }
  }
  existing_subnets_main = {
    "one"     = { az = local.dyn_az_a, create_subnet = false, set = "my" }
    "eleven"  = { az = local.dyn_az_b, create_subnet = false, set = "my" }
    "sixteen" = { az = local.dyn_az_a, create_subnet = false, set = "second", create_route_table = false, route_table_name = local.dyn_rtname }
    "cat"     = { az = local.dyn_az_b, create_subnet = false, set = "second", create_route_table = false, route_table_name = local.dyn_rtname }
  }
  added_subnets_existing_rt = {
    "10.0.50.0/24" = { az = local.dyn_az_a, set = "third", name = local.dyn_s1name, create_route_table = false, route_table_name = local.dyn_rtname }
    "10.0.60.0/24" = { az = local.dyn_az_b, set = "third", name = local.dyn_s2name, create_route_table = false, route_table_name = local.dyn_rtname }
  }
  existing_subnets_existing_rt = {
    "c"            = { az = local.dyn_az_a, create_subnet = false, name = local.dyn_s1name, route_table_name = local.dyn_rtname }
    "d"            = { az = local.dyn_az_b, create_subnet = false, name = local.dyn_s2name, route_table_name = local.dyn_rtname }
    "10.0.90.0/24" = { az = data.aws_availability_zones.this.names[2] } # minor test: while reading some existing subnets, can we add a new one?
  }
}

module "vpc" {
  for_each = toset([local.vpcname, "second"])
  source   = "../../modules/vpc"

  create_vpc              = true
  name                    = each.key
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = var.switchme ? ["10.5.0.0/16"] : ["10.4.0.0/16", "10.5.0.0/16", "10.6.0.0/16"]
  create_internet_gateway = false
  enable_dns_hostnames    = local.dyn_input_switch
  global_tags             = { "Is DNS Enabled" = local.dyn_input_switch }
}

module "subnet_sets" {
  for_each = toset(distinct([for _, v in local.subnets_main : v.set]))
  source   = "../../modules/subnet_set"

  name   = each.key
  vpc_id = module.vpc[local.vpcname].id
  cidrs  = { for k, v in local.subnets_main : k => v if v.set == each.key }

  create_shared_route_table = each.key == "second" # the "second" gets true, all the others get false
}

### Reuse Existing Resources ###

module "existing_vpc" {
  for_each = module.vpc
  source   = "../../modules/vpc"

  create_vpc              = false
  name                    = each.value.name
  create_internet_gateway = var.switchme # minor test: can we add an igw
}

module "added_subnet_sets_existing_rt" {
  for_each = toset(distinct([for _, v in local.added_subnets_existing_rt : v.set]))
  source   = "../../modules/subnet_set"

  name   = each.key
  vpc_id = module.existing_vpc[local.vpcname].id # test: can existing_vpc module detect a vpc_id
  cidrs  = { for k, v in local.added_subnets_existing_rt : k => v if v.set == each.key }

  depends_on = [module.subnet_sets]
}

module "existing_subnet_sets_main" {
  for_each = toset(distinct([for _, v in local.existing_subnets_main : v.set]))
  source   = "../../modules/subnet_set"

  name   = each.key
  vpc_id = module.existing_vpc[local.vpcname].id # test: can existing_vpc module detect a vpc_id
  cidrs  = { for k, v in local.existing_subnets_main : k => v if v.set == each.key }

  depends_on = [module.subnet_sets]
}

module "existing_subnet_set" {
  source = "../../modules/subnet_set"

  name   = "their" # Minor test case: can we discover subnets by individual names, not depending on a module-level `name = "my"`
  vpc_id = module.existing_vpc[local.vpcname].id
  cidrs  = local.existing_subnets_existing_rt

  depends_on = [module.subnet_sets, module.added_subnet_sets_existing_rt]
}

module "existing_subnet_set_sharedrt" {
  source = "../../modules/subnet_set"

  name   = "sharedrt"
  vpc_id = module.existing_vpc[local.vpcname].id
  cidrs = {
    "c" = { az = local.dyn_az_a, create_subnet = false, name = local.dyn_s1name, route_table_name = local.dyn_rtname }
    "d" = { az = local.dyn_az_b, create_subnet = false, name = local.dyn_s2name, route_table_name = local.dyn_rtname }
  }

  depends_on = [module.subnet_sets, module.added_subnet_sets_existing_rt]
}

module "added_subnet_set" {
  source = "../../modules/subnet_set"

  name   = "added-"
  vpc_id = module.existing_vpc[local.vpcname].id
  cidrs = {
    "10.0.70.0/24" = { az = local.dyn_az_a }
    "10.0.80.0/24" = { az = local.dyn_az_b }
  }
}

### Test Results ###

resource "random_pet" "consume_vpc_first_routing_cidrs" {
  for_each = module.vpc[local.vpcname].routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_vpc_second_routing_cidrs" {
  for_each = module.vpc["second"].routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_existing_vpc_second_routing_cidrs" {
  for_each = module.existing_vpc["second"].routing_cidrs

  prefix = each.key
}

resource "random_pet" "consume_existing_subnet_set_availability_zones" {
  for_each = module.existing_subnet_set.availability_zones

  prefix = each.key
}

resource "random_pet" "consume_existing_subnet_set_subnet_names" {
  for_each = module.existing_subnet_set.subnet_names

  prefix = each.key
}

resource "random_pet" "consume_existing_subnet_set_route_tables" {
  for_each = module.existing_subnet_set.route_tables

  prefix = each.key
}

resource "random_pet" "consume_existing_subnet_set_subnets" {
  for_each = module.existing_subnet_set.subnets

  prefix = each.key
}

resource "random_pet" "consume_added_subnet_set_availability_zones" {
  for_each = module.added_subnet_set.availability_zones

  prefix = each.key
}

resource "random_pet" "consume_added_subnet_set_subnet_names" {
  for_each = module.added_subnet_set.subnet_names

  prefix = each.key
}

resource "random_pet" "consume_added_subnet_set_route_tables" {
  for_each = module.added_subnet_set.route_tables

  prefix = each.key
}

resource "random_pet" "consume_added_subnet_set_subnets" {
  for_each = module.added_subnet_set.subnets

  prefix = each.key
}

output "is_subnet_cidr_correct" {
  value = (try(module.existing_subnet_set.subnets[local.dyn_az_a].cidr_block, null) == "10.0.50.0/24")
}

output "is_subnet_name_correct" {
  value = (try(module.added_subnet_set.subnet_names[local.dyn_az_b], null) == "added-b")
}

output "is_subnet_id_not_null" {
  value = module.existing_subnet_set.subnets[local.dyn_az_a].id != null
}

output "is_subnet_id_correct" {
  value = module.existing_subnet_set.subnets[local.dyn_az_a].id == module.added_subnet_sets_existing_rt["third"].subnets[local.dyn_az_a].id
}
