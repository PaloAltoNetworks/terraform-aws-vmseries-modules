output "mgmt_ip_address" {
  description = "Panorama management IP address. If `create_public_ip` was `true`, it is a public IP address, otherwise a private IP address."
  value       = try(aws_eip.this[0].public_ip, aws_instance.this.private_ip)
}
