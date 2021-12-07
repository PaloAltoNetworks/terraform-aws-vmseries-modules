# Optional routes across the peering.
# Currently AWS only supports static routes, and not propagations, across a peering.
#
# As an example, assume:
#   - the west hosts a VPC named "security"
#   - the north hosts a spoke VPC named "panorama"

resource "aws_ec2_transit_gateway_route" "from_panorama_to_west" {
  provider = aws.north

  destination_cidr_block         = "10.0.0.0/8"
  transit_gateway_route_table_id = module.transit_gateway_north.route_tables["from_spoke_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  blackhole                      = false
}

resource "aws_ec2_transit_gateway_route" "from_security_to_north" {
  destination_cidr_block         = "10.244.0.0/16"
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_security_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  blackhole                      = false
}
