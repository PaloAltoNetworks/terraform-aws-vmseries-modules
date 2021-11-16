output "vpc_id" {
  value = var.vpc_id
}

output "subnets" {
  value = local.subnets
}

output "subnet_names" {
  value = { for k, v in local.input_subnets : k => v.name }
}

output "route_tables" {
  value = local.route_tables
}

output "unique_route_table_ids" {
  value = var.create_shared_route_table ? { "shared" = aws_route_table.shared["shared"].id } : { for k, v in aws_route_table.this : k => v.id }
}

output "availability_zones" {
  value = toset(keys(local.input_subnets))
}
