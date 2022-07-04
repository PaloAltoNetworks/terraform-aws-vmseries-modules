output "panorama_url" {
  description = "Panorama instance URL."
  value       = "https://${module.panorama.mgmt_ip_public_address}"
}

output "panorama_private_ip" {
  description = "Panorama instance private IP."
  value       = module.panorama.mgmt_ip_private_address
}