### eu-west-3 ###

provider "aws" {
  region = "eu-west-3"
}

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name = "${var.prefix_name_tag}west-tgw"
  asn  = 65001
  route_tables = {
    "from_security_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from_spokes"
    }
  }
}

### eu-north-1 ###

provider "aws" {
  alias  = "north"
  region = "eu-north-1"
}

module "transit_gateway_north" {
  source = "../../modules/transit_gateway"
  providers = {
    aws = aws.north
  }

  name = "${var.prefix_name_tag}north-tgw"
  asn  = 65000
  route_tables = {
    "from_spoke_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from_spokes"
    }
  }
}

### cross-region ###

module "transit_gateway_peering" {
  source = "../../modules/transit_gateway_peering"
  providers = {
    aws      = aws
    aws.peer = aws.north
  }

  local_tgw_route_table = module.transit_gateway.route_tables["from_spoke_vpc"]
  peer_tgw_route_table  = module.transit_gateway_north.route_tables["from_spoke_vpc"]

  local_attachment_tags = { Name = "west-to-north-attach" }
}
