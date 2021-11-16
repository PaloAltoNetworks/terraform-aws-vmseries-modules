output "firewalls" {
  value = {
    for k, f in aws_instance.pa_vm_series :
    k => f
  }
}
