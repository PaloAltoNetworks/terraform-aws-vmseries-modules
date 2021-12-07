
provider "aws" {
  region = "eu-north-1"
}

provider "aws" {
  alias  = "peer"
  region = "eu-west-3"
}

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name = "panorama-tgw"
  asn  = 65001
  route_tables = {
    "from-peered-tgw" = {
      create = true
      name   = "from-peered-tgw"
    }
    "from-panorama-vpc" = {
      create = true
      name   = "from-panorama-vpc"
    }
  }
}

module "transit_gateway_peering" {
  source = "../../modules/transit_gateway_peering"
  providers = {
    aws      = aws
    aws.peer = aws.peer
  }

  local_tgw_route_table = module.transit_gateway.route_tables["from-peered-tgw"]
  peer_tgw_route_table = {
    # The peer's "spokes" route table, as panorama is just one of the many spokes.
    id                 = "tgw-rtb-0e086e52fba64496c"
    transit_gateway_id = "tgw-010483984dbdb0d45"
  }
  local_attachment_tags = { Name = "panorama-attach" }
}

resource "aws_ec2_transit_gateway_route" "from_panorama_to_peer" {
  destination_cidr_block         = "10.0.0.0/8"
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from-panorama-vpc"].id
  blackhole                      = false
}

resource "aws_ec2_transit_gateway_route" "from_peer_to_panorama" {
  provider = aws.peer

  destination_cidr_block         = "10.244.0.0/16"
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  transit_gateway_route_table_id = "tgw-rtb-0ae118292f1184ce9" # The one that handles the peer's VM-Series management traffic.
  blackhole                      = false
}
