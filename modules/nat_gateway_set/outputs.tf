output next_hop_set {
  description = <<-EOF
  The Next Hop Set object, useful as the input to the `vpc_route` module. Example:

  ```
  next_hop_set = {
    ids = {
      "us-east-1a" = "nat-0ddf598f93a8ea8ae"
      "us-east-1b" = "nat-0862c4b707b012111"
    }
    id = null
    type = "nat_gateway"
  }
  ```
  EOF
  value = {
    type = "nat_gateway"
    id   = null
    ids  = { for k, v in local.nat_gateways : k => v.id }
  }
}

output nat_gateways {
  description = "The map of NAT Gateway objects."
  value       = local.nat_gateways
}

output eips {
  description = "The map of Elastic IP objects. Only valid if `create_nat_gateway` is at the default true value."
  value       = var.create_nat_gateway ? local.eips : {}
}
