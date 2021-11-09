output "firewalls" {
  value = {
    for k, f in aws_instance.pa_vm_series :
    k => f
  }
}

output "raw_network_interfaces" {
  value = aws_network_interface.this
}

output "network_interfaces" {
  value = { for k, v in local.interfaces : k => merge(v,
    {
      id         = aws_network_interface.this[k].id
      private_ip = aws_network_interface.this[k].private_ip
    })
  }
}
