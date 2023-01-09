output "routes_cidr" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.cidr]]))
}

output "routes_mpl" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.mpl]]))
}

output "routes_next_hop_gateway" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_gateway_id]]))
}

output "routes_next_hop_transit_gateway" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_transit_gateway_id]]))
}
