output "instance" {
  value = aws_instance.this
}

output "interfaces" {
  description = "Map of VM-Series network interfaces. The entries are `aws_network_interface` objects."
  value       = aws_network_interface.this
}

output "public_ips" {
  description = "Map of newly created AWS EIPs associated with this VM-Series instance. The entries are `aws_eip` objects."
  value       = aws_eip.this
}
