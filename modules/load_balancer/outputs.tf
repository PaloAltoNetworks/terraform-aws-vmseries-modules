output "lb_fqdn" {
  value = aws_lb.this.dns_name
}