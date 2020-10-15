output "vpc" {
  description = "VPC attributes"
  value       = local.combined_vpc
}

output "subnet_ids" {
  value = local.combined_subnets
}

output "route_table_ids" {
  value = {
    for key, route_table in aws_route_table.this:
    key => route_table.id
  }
}