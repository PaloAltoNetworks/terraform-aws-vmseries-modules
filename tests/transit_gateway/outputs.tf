output "tgw_id" {
  value = module.transit_gateway.transit_gateway.id
}

output "tgw_arn" {
  value = module.transit_gateway.transit_gateway.arn
}

output "tgw_route_tables" {
  value = [for k, v in module.transit_gateway.route_tables : v.tags["Name"]]
}
