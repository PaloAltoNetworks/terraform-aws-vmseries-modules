output "next_hop_set" {
  description = <<-EOF
  The Next Hop Set object, useful as an input to the `vpc_route` module. The intention would
  be to route traffic from subnets to endpoints while preventing cross-AZ traffic (so
  that a subnet in AZ-a only routes to an endpoint in AZ-a). Example:

  ```
  next_hop_set = {
    ids = {
      "us-east-1a" = "gwlbe-0ddf598f93a8ea8ae"
      "us-east-1b" = "gwlbe-0862c4b707b012111"
    }
    id   = null
    type = "vpc_endpoint"
  }
  ```
  EOF
  value = {
    type = "vpc_endpoint"
    id   = null
    ids  = { for k, _ in var.subnets : k => aws_vpc_endpoint.this[k].id }
  }
}

output "endpoints" {
  description = "Map of the created endpoints. The keys are the same as the keys of the input `subnets`."
  value       = aws_vpc_endpoint.this
}
