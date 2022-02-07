output "instance" {
  value = aws_instance.this
}

output "interfaces" {
  description = <<-EOF
  Map of VM-Series network interfaces. The entries in the map are `aws_network_interface` objects.
  If a map is needed instead, following code can be used:

  ```
  { for k, v in module.this.interfaces : var.interfaces[k].name => v }
  ```
  EOF
  value       = aws_network_interface.this
}
