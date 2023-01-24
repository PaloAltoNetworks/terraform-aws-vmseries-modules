output "route_details" {
  value = [for k, v in aws_route.this : {
    cidr                               = v.destination_cidr_block
    mpl                                = v.destination_prefix_list_id
    rtb                                = v.route_table_id
    next_hop_transit_gateway_id        = try(v.transit_gateway_id, null)
    next_hop_gateway_id                = try(v.gateway_id, null)
    next_hop_nat_gateway_id            = try(v.nat_gateway_id, null)
    next_hop_network_interface_id      = try(v.network_interface_id, null)
    next_hop_vpc_endpoint_id           = try(v.vpc_endpoint_id, null)
    next_hop_vpc_peering_connection_id = try(v.vpc_peering_connection_id, null)
    next_hop_egress_only_gateway_id    = try(v.egress_only_gateway_id, null)
    next_hop_local_gateway_id          = try(v.local_gateway_id, null)
    }
  ]
}