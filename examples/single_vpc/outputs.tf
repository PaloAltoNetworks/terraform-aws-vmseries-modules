output "vpc_id" {
  value = module.vpc.id
}

output "security_group_ids" {
  value = module.vpc.security_group_ids
}
