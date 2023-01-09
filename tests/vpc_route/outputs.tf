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

output "routes_next_hop_nat_gateway" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_nat_gateway_id]]))
}

output "routes_next_hop_network_interface" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_network_interface_id]]))
}

output "routes_next_hop_vpc_endpoint" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_vpc_endpoint_id]]))
}

output "routes_next_hop_vpc_peering_connection" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_vpc_peering_connection_id]]))
}

output "routes_next_hop_egress_only_gateway" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_egress_only_gateway_id]]))
}

output "routes_next_hop_local_gateway" {
  value = compact(flatten([for k, v in module.security_vpc_routes : [for i in v.route_details : i.next_hop_local_gateway_id]]))
}
