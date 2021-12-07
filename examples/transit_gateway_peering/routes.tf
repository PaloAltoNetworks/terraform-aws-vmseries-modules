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
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_security_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_peering.peering_attachment.id
  blackhole                      = false

  # Workaround: Explicit depends_on ensures that peering_attachment is already accepted when creating this route.
  depends_on = [module.transit_gateway_peering]
}
