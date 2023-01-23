output "public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

output "vmseries_url" {
  description = "VM-Series instance URL."
  value       = "https://${module.vmseries["vmseries01"].public_ips["mgmt"]}/php/login.php"
}
