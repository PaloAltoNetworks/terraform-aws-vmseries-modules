output "tgw_id" {
  value = module.transit_gateway.transit_gateway.id
}

output "tgw_arn" {
  value = module.transit_gateway.transit_gateway.arn
}

output "tgw_route_tables" {
  value = [for k, v in module.transit_gateway.route_tables : v.tags["Name"]]
}

output "tgw_attachment_next_hop_set" {
  value = length(var.transit_gateway_route_tables) > 0 ? module.security_transit_gateway_attachment[0].next_hop_set : null
}

output "tgw_attachment_next_hop_set_tgw_id" {
  value = length(var.transit_gateway_route_tables) > 0 ? module.security_transit_gateway_attachment[0].next_hop_set.id : null
}