output "mgmt_ip_private_address" {
  description = "Panorama private IP address."
  value       = try(aws_instance.this.private_ip)
}

output "mgmt_ip_public_address" {
  description = "Panorama management IP address. If `create_public_ip` was `true`, it will receive IP address otherwise it show message with no public IP info."
  value       = try(aws_eip.this[0].public_ip, "no public IP in Panorama.")
}
