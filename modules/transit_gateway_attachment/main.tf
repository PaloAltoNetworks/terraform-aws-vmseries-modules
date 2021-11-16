resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  vpc_id                                          = var.vpc_id
  subnet_ids                                      = [for _, subnet in var.subnets : subnet.id]
  transit_gateway_id                              = var.transit_gateway_route_table.transit_gateway_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = var.appliance_mode_support
  dns_support                                     = var.dns_support
  ipv6_support                                    = var.ipv6_support
  tags                                            = merge(var.tags, var.name != null ? { Name = var.name } : {})
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.transit_gateway_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = var.propagate_routes_to

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = each.value
}
