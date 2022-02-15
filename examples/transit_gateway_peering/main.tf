### Local Region (eu-west-3) ###

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name = "${var.prefix_name_tag}${var.region}-tgw-1"
  asn  = 65001
  route_tables = {
    "from_security_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from-security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from-spokes"
    }
  }
}

### Remote Region (eu-north-1) ###

# To be able to interact at all with a different AWS region, we need to declare
# an alternative provider to what is normally defined in versions.tf.
provider "aws" {
  alias  = "remote"
  region = var.remote_region
}

module "transit_gateway_remote" {
  source = "../../modules/transit_gateway"
  providers = {
    aws = aws.remote
  }

  name = "${var.prefix_name_tag}${var.remote_region}-tgw-2"
  asn  = 65000
  route_tables = {
    "from_spoke_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from-spokes"
    }
  }
}

### Cross-Region ###

module "transit_gateway_peering" {
  source = "../../modules/transit_gateway_peering"
  providers = {
    aws        = aws
    aws.remote = aws.remote
  }

  local_tgw_route_table  = module.transit_gateway.route_tables["from_spoke_vpc"]
  remote_tgw_route_table = module.transit_gateway_remote.route_tables["from_spoke_vpc"]

  local_attachment_tags = { Name = "${var.prefix_name_tag}peering-attach" }
}
