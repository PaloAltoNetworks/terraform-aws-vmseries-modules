output transit_gateway_ids {
  description = "TGW Name -> ID Map (New AND Existing)"
  value       = local.combined_transit_gateways
}

output "transit_gateway_route_table_ids" {
  description = "TGW Route Table Name -> ID Map (New AND Existing)"
  value = local.combined_transit_gateway_route_tables
}