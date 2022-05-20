output "panorama_url" {
  description = "Panorama instance URL."
  value       = "https://${module.panorama.mgmt_ip_address}"
}

output "exit_user_information" {
  description = "Post Deployment info."
  value       = "Wait at least 15 min since Panorama is still configure after deployment."
}
