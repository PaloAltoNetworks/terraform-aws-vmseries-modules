output "target_group" {
  value = aws_lb_target_group.this
}

output "endpoint_service" {
  value = aws_vpc_endpoint_service.this
}
