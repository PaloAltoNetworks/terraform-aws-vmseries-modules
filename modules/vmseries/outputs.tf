output "instance" {
  value = aws_instance.this
}

output "interfaces" {
  description = "Map of VM-Series network interfaces. The entries are `aws_network_interface` objects."
  value       = aws_network_interface.this
}
