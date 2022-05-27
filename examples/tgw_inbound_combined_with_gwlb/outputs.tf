##### Security VPC #####

output "security_gwlb_service_name" {
  description = "The AWS Service Name of the created GWLB, which is suitable to use for subsequent VPC Endpoints."
  value       = module.security_gwlb.endpoint_service.service_name
}

output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

##### App1 VPC #####

output "app1_inspected_dns_name" {
  description = "The DNS name that you can use to SSH into a testbox. Use username `bitnami` and the private key matching the public key configured with the input `ssh_public_key_file_path`."
  value       = module.app1_lb.lb_dns_name
}

output "app1_inspected_public_ip" {
  description = "The IP address behind the `app1_inspected_dns_name`."
  value       = aws_eip.lb.public_ip
}
