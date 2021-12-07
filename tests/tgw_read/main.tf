#
#
# Test whether existing TGW and TGWA could be read.

# The code below fetches Availability Zones but leaves out the Local Zones and Wavelength Zones.
data "aws_availability_zones" "this" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "random_pet" "this" {
  prefix = "test-tgw-read"
}

# The values that are unknown until the Terraform's apply phase runs.
locals {
  u_true     = length(random_pet.this.id) > 0
  u_false    = length(random_pet.this.id) < 0
  u_vpcname  = "test-tgw-read-vpc-${random_pet.this.id}"
  u_tgwname  = "test-tgw-read-tgw-${random_pet.this.id}"
  u_tgwaname = "test-tgw-read-tgwa-${random_pet.this.id}"
  u_rtname   = "test-tgw-read-rt-${random_pet.this.id}"
  u_s1name   = "test-tgw-read-s1-${random_pet.this.id}" # TODO use it
  u_s2name   = "test-tgw-read-s2-${random_pet.this.id}"
  az_a       = data.aws_availability_zones.this.names[0]
  az_b       = data.aws_availability_zones.this.names[1]
}

module "vpc" {
  source = "../../modules/vpc"

  name                    = local.u_vpcname
  cidr_block              = "10.105.0.0/16"
  create_internet_gateway = false
}

module "subnet_sets" {
  for_each = toset(["first", "second"])
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.vpc.id
  has_secondary_cidrs = module.vpc.has_secondary_cidrs

  create_shared_route_table = each.key == "second" # "first" gets false, "second" gets true
  cidrs = {
    for k, v in {
      "10.105.15.0/25" = { az = local.az_a, set = "first" }
      "10.105.16.0/25" = { az = local.az_b, set = "first" }
      "10.105.25.0/25" = { az = local.az_a, set = "second", route_table_name = local.u_rtname }
      "10.105.26.0/25" = { az = local.az_b, set = "second", route_table_name = local.u_rtname }
    } : k => v if v.set == each.key
  }
}

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name = local.u_tgwname # minor test: name is not static
  route_tables = {
    "from_spokes" = { name = "from_spokes", create = true }
  }
}

### Reuse Existing Resources ###

module "transit_gateway_read" {
  source = "../../modules/transit_gateway"

  name   = module.transit_gateway.name
  create = false
  route_tables = {
    "from_spokes"   = { name = "from_spokes", create = false }
    "from_security" = { name = "from_security", create = true }
  }

  depends_on = [module.transit_gateway]
}

module "transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = local.u_tgwaname # minor test: name is not static
  transit_gateway_route_table = module.transit_gateway_read.route_tables["from_spokes"]
  vpc_id                      = module.subnet_sets["first"].vpc_id
  subnets                     = module.subnet_sets["first"].subnets
}
