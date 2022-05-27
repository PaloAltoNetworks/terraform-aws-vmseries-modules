output "fw_public_ips" {
  description = "A map of Firewalls' public IPs."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

output "public_lb_fqdn" {
  description = "Fully Qualified Domain Names for Load Balancer in front of the Firewalls."
  value = {
    application_load_balancer = module.public_alb.lb_fqdn
    network_load_balancer     = module.public_nlb.lb_fqdn
  }
}

output "app_vm_ips" {
  description = "A map private IP addresses assigned to Application VMs."
  value = { for k, v in aws_instance.app_vm : k => v.private_ip
  }
}

output "app_lb_fqdn" {
  description = "Fully Qualified Domain Name of the internal Network Load Balancer placed in front of the Application VMs."
  value       = module.app_nlb.lb_fqdn
}