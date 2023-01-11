output "panorama_url" {
  description = "Panorama instance URL."
  value       = "https://${module.panorama.mgmt_ip_public_address}"
}

output "panorama_private_ip" {
  description = "Panorama instance private IP."
  value       = module.panorama.mgmt_ip_private_address
}

output "generated_private_key" {
  value     = tls_private_key.generated_key.private_key_pem
  sensitive = true
}