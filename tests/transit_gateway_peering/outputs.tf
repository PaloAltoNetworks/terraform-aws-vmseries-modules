output "tgw_local_id" {
  value = module.transit_gateway_local.transit_gateway.id
}

output "tgw_local_arn" {
  value = module.transit_gateway_local.transit_gateway.arn
}

output "tgw_remote_id" {
  value = module.transit_gateway_remote.transit_gateway.id
}

output "tgw_remote_arn" {
  value = module.transit_gateway_remote.transit_gateway.arn
}

output "route_destination_from_remote_spoke_to_local_region" {
  value = aws_ec2_transit_gateway_route.from_remote_spoke_to_local_region.destination_cidr_block
}

output "route_destination_from_local_security_to_remote_region" {
  value = aws_ec2_transit_gateway_route.from_local_security_to_remote_region.destination_cidr_block
}
