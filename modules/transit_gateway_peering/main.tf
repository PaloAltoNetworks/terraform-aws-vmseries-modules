# Why is the code split between module `transit_gateway` and `transit_gateway_peering`?
#
# With TGW peering, the module which creates an Attachment needs to see first *both* TGWs completed.
# And then, Accepter needs to see the Attachment completed.
# Hence Accepter cannot be created in the same module as its TGW, because the module first needs
# to emit the TGW identifier and then wait for Attachment identifier to become usable.
# Since both the Route Tables can be only associated after the Accepter finishes, the dependency
# hassle is minimized by putting together Peering Attachment + Peering Accepter + Peering Route Tables
# in the same module.
# The downside of this choice is that the resulting module needs two AWS providers, not one.

##### Request from the "local" region to the "remote" region #####

resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  peer_account_id         = data.aws_caller_identity.remote.account_id
  peer_region             = data.aws_region.remote_region.name
  peer_transit_gateway_id = var.remote_tgw_route_table.transit_gateway_id
  transit_gateway_id      = var.local_tgw_route_table.transit_gateway_id
  tags                    = merge(var.tags, var.local_attachment_tags)
}

resource "aws_ec2_transit_gateway_route_table_association" "local" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this.id
  transit_gateway_route_table_id = var.local_tgw_route_table.id

  # Workaround for apply error "IncorrectState: tgw-attach-1 is in invalid state" (i.e. unaccepted).
  depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.remote]
}

# The aws_ec2_transit_gateway_route_table_propagation here wouldn't be supported by AWS, failing with:
# "You cannot propagate a peering attachment to a Transit Gateway Route Table".

##### Accept from the "remote" region to the "local" region #####

# Accepter is the "other side" of the peering.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "remote" {
  provider = aws.remote

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this.id
  tags                          = var.tags
}

# One route table per TGW per peering, otherwise it fails with "tgw-attach-1 is already associated to a route table".
resource "aws_ec2_transit_gateway_route_table_association" "remote" {
  provider = aws.remote

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.remote.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.remote_tgw_route_table.id
}

# Determine the peer's region by looking at its provider.
data "aws_region" "remote_region" {
  provider = aws.remote
}

# Determine the peer's AWS Account by looking at its provider.
data "aws_caller_identity" "remote" {
  provider = aws.remote
}
