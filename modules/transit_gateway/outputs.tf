output "name" {
  description = "Same as the input `name`."
  value       = var.name
}

output "transit_gateway" {
  description = "The entire object `aws_ec2_transit_gateway`."
  value       = local.transit_gateway
}

output "route_tables" {
  value = local.transit_gateway_route_tables
}
