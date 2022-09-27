variable "route_table_ids" {
  description = <<-EOF
  A map of Route Tables where to install the route. Each key is an arbitrary string,
  each value is a Route Table identifier. The keys need to match keys used in the
  `next_hop_set` input. The keys are usually Availability Zone names. Each of the Route Tables
  obtains exactly one next hop from the `next_hop_set`. Example:
  ```
  route_table_ids = {
    "us-east-1a" = "rt-123123"
    "us-east-1b" = "rt-123456"
  }
  ```
  EOF
  type        = map(string)
}

variable "next_hop_set" {
  description = <<-EOF
  The Next Hop Set object, such as an output `module.nat_gateway_set.next_hop_set`, which contains 3 attributes:
  - `type`
  - `id`
  - `ids`

  For `type` attribute there are possible below values:
  - "transit_gateway"
  - "internet_gateway"
  - "vpc_peer"
  - "egress_only_gateway"
  - "local_gateway"
  - "nat_gateway"
  - "interface"
  - "vpc_endpoint"

  The set of single-zone next hops (type "nat_gateway", "interface" and "vpc_endpoint") should be specified as the `ids` map, in which case each value is a next hop id and each key should be present among the keys of the input `route_table_ids`. To avoid unintended cross-zone routing, these keys should be equal. Example:
  ```
  next_hop_set = {
    type = "nat_gateway"
    id   = null
    ids  = {
      "us-east-1a" = "natgw-123"
      "us-east-1b" = "natgw-124"
    }
  }
  ```

  For a non-AZ-aware next hop (type "transit_gateway", "internet_gateway", "vpc_peer", "egress_only_gateway" and "local_gateway"), the `ids` map should be empty. All the route tables receive the same `id` of the next hop. Example:
  ```
  next_hop_set = {
    type = "internet_gateway"
    id   = "igw-12345"
    ids  = {}
  }
  ```
  EOF
  type = object({
    type = string
    id   = string
    ids  = map(string)
  })
  validation {
    condition = (
      length(var.next_hop_set.ids) == 0 && (var.next_hop_set.type == "transit_gateway" || var.next_hop_set.type == "internet_gateway" || var.next_hop_set.type == "vpc_peer" || var.next_hop_set.type == "egress_only_gateway" || var.next_hop_set.type == "local_gateway")
      || var.next_hop_set.id == null && (var.next_hop_set.type == "nat_gateway" || var.next_hop_set.type == "interface" || var.next_hop_set.type == "vpc_endpoint")
    )
    error_message = "Map of ids should be empty for next hop types: \"transit_gateway\", \"internet_gateway\", \"vpc_peer\", \"egress_only_gateway\", \"local_gateway\". Attribute id should be empty for next hop types: \"nat_gateway\", \"interface\", \"vpc_endpoint\"."
  }
}

variable "to_cidr" {
  description = "The CIDR to match the packet's destination field. If they match, the route can be used for the packet. For example \"0.0.0.0/0\"."
  type        = string
}

variable "cidr_type" {
  description = "Type of `to_cidr`, either \"ipv4\" or \"ipv6\"."
  default     = "ipv4"
  type        = string
}
