output "target_group" {
  value = aws_lb_target_group.this
}

output "lb_fqdn" {
  description = "A FQDN for the Load Balancer."
  value       = aws_lb.this.dns_name
}
