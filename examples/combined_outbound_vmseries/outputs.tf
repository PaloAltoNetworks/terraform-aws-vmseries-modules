##### Security VPC #####

output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

##### App VPC #####

output "app_inspected_dns_name" {
  description = <<-EOF
  FQDN of App Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = [for l in module.app_lb : l.lb_fqdn]
}
