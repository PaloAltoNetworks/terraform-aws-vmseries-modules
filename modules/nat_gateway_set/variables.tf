variable create_nat_gateway {
  description = "If false, does not create a new NAT Gateway, but instead reads a pre-existing one."
  default     = true
  type        = bool
}

variable create_eip {
  description = "If false, does not create a new Elastic IP, but instead reads a pre-existing one. This input is ignored if `create_nat_gateway` is false."
  default     = true
  type        = bool
}

variable eips {
  description = <<-EOF
    Optional map of Elastic IP attributes. Each key is an Availability Zone name, for example "us-east-1b". Each entry has optional attributes `name`, `public_ip`, `id`.
    These are mainly useful to select a pre-existing Elastic IP when create_eip is false. Example:

    ```
    eips = {
        "us-east-1a" = { id = aws_eip.a.id }
        "us-east-1b" = { id = aws_eip.b.id }
    }
    ```

    The `name` attribute can be used both for selecting the pre-existing Elastic IP, or for customizing a newly created Elastic IP:

    ```
    eips = {
        "us-east-1a" = { name = "Alice" }
        "us-east-1b" = { name = "Bob" }
    }
    ```
    EOF
  default     = {}
}

variable nat_gateway_names {
  description = "A map, where each key is an Availability Zone name, for example \"us-east-1b\". Each value in the map is a custom name of a NAT Gateway in that Availability Zone. The name is kept in an AWS standard Name tag."
  default     = {}
  type        = map(string)
}

variable subnet_set {
  description = "The subnet set object that owns this NAT Gateway set. The result of the call to the module `subnet_set`, for example `subnet_set = module.natgw_subnet_set`."
  default     = true
}

variable nat_gateway_tags {
  default = {}
  type    = map(string)
}

variable eip_tags {
  default = {}
  type    = map(string)
}

variable global_tags {
  default = {}
  type    = map(string)
}
