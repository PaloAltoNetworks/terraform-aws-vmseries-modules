output "name" {
  description = "Same as the input `name`."
  # Referencing the actual NAME TAG gives us access to it's value for TGWs referenced only by ID.
  value = try(local.transit_gateway.tags.Name, null)
}

output "transit_gateway" {
  description = "The entire object `aws_ec2_transit_gateway`."
  value       = local.transit_gateway
}

output "route_tables" {
  value = local.transit_gateway_route_tables
}
