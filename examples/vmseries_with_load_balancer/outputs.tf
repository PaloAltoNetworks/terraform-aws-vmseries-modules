output "fw_public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

output "public_lb_fqdn" {
  value = module.public_nlb.lb_fqdn
}

output "lb_private_ips" {
  value = module.public_nlb.lb_private_ips
}