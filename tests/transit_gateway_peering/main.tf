### Local Region ###

module "transit_gateway_local" {
  source = "../../modules/transit_gateway"

  name = var.local_transit_gateway_name != null ? "${var.name_prefix}${var.region}-${var.local_transit_gateway_name}" : null
  asn  = var.local_transit_gateway_asn
  route_tables = {
    "from_security_vpc" = {
      create = true
      name   = "${var.name_prefix}from-security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "${var.name_prefix}from-spokes"
    }
  }
}

### Remote Region ###

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

  name = var.remote_transit_gateway_name != null ? "${var.name_prefix}${var.remote_region}-${var.remote_transit_gateway_name}" : null
  asn  = var.remote_transit_gateway_asn
  route_tables = {
    "from_spoke_vpc" = {
      create = true
      name   = "${var.name_prefix}from-spokes"
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

  local_tgw_route_table  = module.transit_gateway_local.route_tables["from_spoke_vpc"]
  remote_tgw_route_table = module.transit_gateway_remote.route_tables["from_spoke_vpc"]

  local_attachment_tags = { Name = "${var.name_prefix}peering-attach" }
}

# Optional routes across the peering.
# Currently AWS only supports static routes, and not propagations, across a peering.
#
# As an example, assume:
#   - the local region has a VPC named "security"
#   - the remote region has a VPC named "spoke" (in a typical use case it can host a Panorama management appliance)

resource "aws_ec2_transit_gateway_route" "from_remote_spoke_to_local_region" {
  provider = aws.remote

  destination_cidr_block         = "10.0.0.0/8"
  transit_gateway_route_table_id = module.transit_gateway_remote.route_tables["from_spoke_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  blackhole                      = false

  # Workaround: Explicit depends_on ensures that peering_attachment is already accepted when creating this route.
  depends_on = [module.transit_gateway_peering]
}

resource "aws_ec2_transit_gateway_route" "from_local_security_to_remote_region" {
  destination_cidr_block         = "10.244.0.0/16"
  transit_gateway_route_table_id = module.transit_gateway_local.route_tables["from_security_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  blackhole                      = false

  # Workaround: Explicit depends_on ensures that peering_attachment is already accepted when creating this route.
  depends_on = [module.transit_gateway_peering]
}
