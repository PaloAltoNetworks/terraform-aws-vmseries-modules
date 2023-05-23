##### Security VPC #####

output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

##### App1 VPC #####

output "app1_inspected_dns_name" {
  description = <<-EOF
  FQDN of "app1" Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = { for k, v in module.public_alb : k => v.lb_fqdn }
}
