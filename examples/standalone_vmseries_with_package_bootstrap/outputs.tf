output "bucket_id" {
  value = module.bootstrap.bucket_id
}

output "bucket_name" {
  value = module.bootstrap.bucket_name
}

output "instance_profile_name" {
  value = module.bootstrap.instance_profile_name
}

output "public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}
