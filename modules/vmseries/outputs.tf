output "mgmt_ip_address" {
  description = "VM-Series management IP address. If `create_public_ip` is `true` or `eip_allocation_id` is used, it is a public IP address, otherwise a private IP address."
  value       = can(aws_instance.this.public_ip) ? aws_instance.this.public_ip : aws_instance.this.private_ip

}

output "interfaces" {
  description = "Map of VM-Series network interfaces. The keys of the map are interface names. The values of the map are `aws_network_interface` objects."
  value       = { for k, v in aws_network_interface.this : var.interfaces[k].name => v }
}

output "public_ips" {
  description = "Map of public IPs. The keys of the map are interface names. The values of the map are associated public IPs"
  value       = { for k, v in aws_eip_association.this : var.interfaces[k].name => v.public_ip }
}