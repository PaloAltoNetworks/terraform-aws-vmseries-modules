output "lb_fqdn" {
  description = "A FQDN for the Load Balancer."
  value       = aws_lb.this.dns_name
}

output "lb_private_ips" {
  description = "A map of Load Balancer's private IPs with keys set to AZ names."
  value = {
    for k, v in data.aws_network_interface.this : k => v.private_ip
  }
}
