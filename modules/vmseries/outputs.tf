output "firewalls" {
  value = {
    for k, f in aws_instance.pa-vm-series :
    k => f
  }
}
