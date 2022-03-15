output "lb_fqdn" {
  description = "A FQDN for the Network Load Balancer."
  value       = aws_lb.this.dns_name
}