output "instance" {
  value = aws_instance.this
}

output "interfaces" {
  description = "Map of VM-Series network interfaces. The entries are `aws_network_interface` objects."
  value       = aws_network_interface.this
}

output "public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in aws_eip.this : k => v.public_ip }
}
