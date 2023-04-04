##### Security VPC #####

output "security_gwlb_service_name" {
  description = "The AWS Service Name of the created GWLB, which is suitable to use for subsequent VPC Endpoints."
  value       = module.security_gwlb.endpoint_service.service_name
}

##### App VPC #####

output "app1_inspected_dns_name" {
  description = <<-EOF
  FQDN of "app1" Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = module.app1_lb.lb_fqdn
}

output "app2_inspected_dns_name" {
  description = <<-EOF
  FQDN of "app2" Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = module.app2_lb.lb_fqdn
}
