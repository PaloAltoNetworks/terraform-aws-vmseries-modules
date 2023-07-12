##### App VPC #####

output "app_inspected_dns_name" {
  description = <<-EOF
  FQDN of App Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = [for l in module.app_lb : l.lb_fqdn]
}

##### VM-Series ALB & NLB #####

output "public_alb_dns_name" {
  description = "FQDN of VM-Series External Application Load Balancer used in centralized design."
  value       = { for k, v in module.public_alb : k => v.lb_fqdn }
}

output "public_nlb_dns_name" {
  description = "FQDN of VM-Series External Network Load Balancer used in centralized design."
  value       = { for k, v in module.public_nlb : k => v.lb_fqdn }
}
