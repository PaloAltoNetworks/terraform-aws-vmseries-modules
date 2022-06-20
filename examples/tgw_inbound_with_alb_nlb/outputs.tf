output "fw_public_ips" {
  description = "A map of Firewalls' public IPs."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

output "lb_fqdns" {
  description = "Fully Qualified Domain Names for all Load Balancers."
  value = {
    public_application_load_balancer = module.public_alb.lb_fqdn
    public_network_load_balancer     = module.public_nlb.lb_fqdn
    internal_network_load_balancer   = module.app_nlb.lb_fqdn
  }
}

output "app_vm_ips" {
  description = "A map private IP addresses assigned to Application VMs."
  value = { for k, v in aws_instance.app_vm : k => v.private_ip
  }
}
