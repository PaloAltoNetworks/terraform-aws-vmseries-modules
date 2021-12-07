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
  u_map = merge(
    { (local.u_string) = local.u_string },
    { knownkey = "knownvalue" },
    # It is unknown whether the merge is a single-element map or a two-element map.
  )
  u_list = keys(local.u_map)
}

### The code under test. ###

module "subnet_set" {
  source = "../../modules/subnet_set"

  # Inputs that cannot handle unknown values.
  cidrs = {
    "10.0.10.0/24" = {
      # Nested attributes that cannot handle unknown values.
      create_subnet         = true,
      create_route_table    = true,
      associate_route_table = false,
      az                    = "eu-dummy-a",
      # Nested attributes that can handle unknown values.
      route_table_name        = local.u_string
      existing_route_table_id = local.u_string
      local_tags              = local.u_map
    }
  }
  create_shared_route_table = false

  # Inputs that can handle unknown values.
  name                    = local.u_string
  vpc_id                  = local.u_string
  map_public_ip_on_launch = local.u_bool
  has_secondary_cidrs     = local.u_bool
  propagating_vgws        = local.u_list
  global_tags             = local.u_map
}

module "nosubnet_set" {
  source = "../../modules/subnet_set"

  # Inputs that cannot handle unknown values.
  cidrs = {
    "10.0.10.0/24" = {
      # Nested attributes that cannot handle unknown values.
      create_subnet         = false, # the change
      create_route_table    = true,
      associate_route_table = false,
      az                    = "eu-dummy-a",
      # Nested attributes that can handle unknown values.
      route_table_name        = local.u_string
      existing_route_table_id = local.u_string
      local_tags              = local.u_map
    }
  }
  create_shared_route_table = false

  # Inputs that can handle unknown values.
  name                    = local.u_string
  vpc_id                  = local.u_string
  map_public_ip_on_launch = local.u_bool
  has_secondary_cidrs     = local.u_bool
  propagating_vgws        = local.u_list
  global_tags             = local.u_map
}

### 

resource "random_pet" "consume_maps" {
  for_each = merge(
    module.subnet_set.subnet_names,
    module.subnet_set.route_tables,
    module.subnet_set.subnets,
    module.subnet_set.unique_route_table_ids,
    # FIXME module.subnet_set.routing_cidrs,
    # TODO  module.subnet_set.ipv6_routing_cidrs,   Invalid for_each argument
    module.nosubnet_set.subnet_names,
    module.nosubnet_set.route_tables,
    module.nosubnet_set.subnets,
    module.nosubnet_set.unique_route_table_ids,
    # FIXME module.nosubnet_set.routing_cidrs,
  )
}

resource "random_pet" "consume_sets" {
  for_each = setunion(
    module.subnet_set.availability_zones,
    module.nosubnet_set.availability_zones,
  )
}
