output "alb_name" {
  value = module.public_alb.lb_fqdn
}

output "vms_public_ips" {
  value = [ for k, v in var.app_vms : aws_instance.app_vm[k].public_ip ]
}