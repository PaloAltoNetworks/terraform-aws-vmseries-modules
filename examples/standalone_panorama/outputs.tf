output "panorama_url" {
  description = "Panorama instance URL."
  value       = "https://${module.panorama.mgmt_ip_address}"
}