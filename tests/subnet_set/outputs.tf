output "vpc_id" {
  value = module.subnet_set.vpc_id
}

output "subnets_cidrs" {
  value = [for k, v in module.subnet_set.subnets : v.cidr_block]
}

output "subnet_names" {
  value = [for k, v in module.subnet_set.subnet_names : v]
}

output "route_tables" {
  value = [for k, v in module.subnet_set.route_tables : v.id]
}

output "availability_zones" {
  value = [for k, v in module.subnet_set.availability_zones : v]
}
