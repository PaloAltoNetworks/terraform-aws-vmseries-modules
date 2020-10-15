output "vpc_id" {
  value = module.vpc_all_options.vpc
}

output "subnet_ids" {
  value = module.vpc_all_options.subnet_ids
}

output "route_table_ids" {
  value = module.vpc_all_options.route_table_ids
}