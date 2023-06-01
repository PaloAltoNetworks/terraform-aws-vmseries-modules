##### Security VPC #####

output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

##### App VPC #####

output "application_load_balancers" {
  description = <<-EOF
  FQDNs of Application Load Balancers
  EOF
  value       = { for k, v in module.public_alb : k => v.lb_fqdn }
}

output "network_load_balancers" {
  description = <<-EOF
  FQDNs of Network Load Balancers.
  EOF
  value       = { for k, v in module.public_nlb : k => v.lb_fqdn }
}
