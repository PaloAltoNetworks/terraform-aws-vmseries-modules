output "fw_public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

output "public_lb" {
  value = {
    fqdn        = module.public_nlb.lb_fqdn
    private_ips = module.public_nlb.lb_private_ips
  }
}

output "private_lb" {
  value = {
    fqdn        = module.private_nlb.lb_fqdn
    private_ips = module.private_nlb.lb_private_ips
  }
}