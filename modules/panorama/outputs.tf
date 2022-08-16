output "mgmt_ip_private_address" {
  description = "Panorama private IP address."
  value       = try(aws_instance.this.private_ip)
}

output "mgmt_ip_public_address" {
  description = "Panorama management IP address. If `create_public_ip` is set to `true`, it will output the public IP address otherwise it will show the 'no public IP assigned to Panorama' message."
  value       = try(aws_eip.this[0].public_ip, "no public IP assigned to Panorama.")
}
