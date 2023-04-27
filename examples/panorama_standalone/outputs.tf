output "panorama_url" {
  description = "Map of URLs for Panorama instances."
  value       = { for k, v in module.panorama : k => "https://${v.mgmt_ip_public_address}" }
}

output "panorama_private_ip" {
  description = "Map of private IPs for Panorama instances."
  value       = { for k, v in module.panorama : k => v.mgmt_ip_private_address }
}

output "panorama_public_ips" {
  description = "Map of public IPs for Panorama instances."
  value       = { for k, v in module.panorama : k => v.mgmt_ip_public_address }
}
