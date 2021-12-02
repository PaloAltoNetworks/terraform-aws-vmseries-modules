##### Security VPC #####

output "security_gwlb_service_name" {
  description = "The AWS Service Name of the created GWLB, which is suitable to use for subsequent VPC Endpoints."
  value       = module.security_gwlb.endpoint_service.service_name
}

##### App1 VPC #####

output "app1_inspected_dns_name" {
  description = <<-EOF
  The DNS name that you can use to SSH into a testbox. Use `ssh ubuntu@<<value>>`
  command with the same public key as given in the `ssh_public_key_path` input."
  EOF
  value       = module.app1_lb.lb_dns_name
}

output "app1_inspected_public_ip" {
  description = "The IP address behind the `app1_inspected_dns_name`."
  value       = aws_eip.lb.public_ip
}
