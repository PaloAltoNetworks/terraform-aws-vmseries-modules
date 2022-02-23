output "public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in module.vmseries : k => v.public_ip }
}
