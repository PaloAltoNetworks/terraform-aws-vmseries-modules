variable "create_nat_gateway" {
  description = "If false, does not create a new NAT Gateway, but instead reads a pre-existing one."
  default     = true
  type        = bool
}

variable "create_eip" {
  description = "If false, does not create a new Elastic IP, but instead reads a pre-existing one. This input is ignored if `create_nat_gateway` is false."
  default     = true
  type        = bool
}

variable "eips" {
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

variable "nat_gateway_names" {
  description = <<EOF
A map, where each key is an Availability Zone name, for example "us-east-1b". Each value in the map is a custom name of a NAT Gateway in that Availability Zone.
The name is kept in an AWS standard Name tag.
  Example:
  ```
  nat_gateway_names = {
    "us-east-1a" = "example-natgwa"
    "us-east-1b" = "example-natgwb"
  }
  ```

  EOF
  default     = {}
  type        = map(string)
}

variable "subnets" {
  description = <<-EOF
  Map of Subnets where to create the NAT Gateways. Each map's key is the availability zone name and each map's object has an attribute `id` identifying AWS Subnet. Importantly, the traffic returning from the NAT Gateway uses the Subnet's route table.
  The keys of this input map are used for the output map `endpoints`.
  Example for users of module `subnet_set`:
  ```
  subnets = module.subnet_set.subnets
  ```
  Example:
  ```
  subnets = {
    "us-east-1a" = { id = "snet-123007" }
    "us-east-1b" = { id = "snet-123008" }
  }
  ```
  EOF
  type = map(object({
    id   = string
    tags = map(string)
  }))
}

variable "nat_gateway_tags" {
  default = {}
  type    = map(string)
}

variable "eip_tags" {
  default = {}
  type    = map(string)
}

variable "global_tags" {
  default = {}
  type    = map(string)
}

variable "eip_domain" {
  description = "Indicates if this EIP is for use in VPC"
  default     = "vpc"
  type        = string
}