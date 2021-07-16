output "next_hop_set" {
  value = {
    type = "vpc_endpoint"
    id   = null
    ids  = { for k, _ in var.subnet_set.subnets : k => aws_vpc_endpoint.this[k].id }
  }
}
