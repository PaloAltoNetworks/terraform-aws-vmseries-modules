output "target_group" {
  value = aws_lb_target_group.this
}

output "endpoints" {
  value = aws_vpc_endpoint.this
}

output "endpoint_ids" {
  description = "Endpoint Name -> ID Map"
  value = {
    for k, endpoint in aws_vpc_endpoint.this :
    k => endpoint.id
  }
}