variable "vpc_id" {
  description = "AWS identifier of a VPC containing the Attachment."
  type        = string
}

variable "subnets" {
  description = <<-EOF
  The attachment's subnets as a map. Each key is the availability zone name and each object has an attribute
  `id` identifying AWS subnet.
  All subnets in the map obtain virtual network interfaces attached to the TGW.
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
    id = string
  }))
}

variable "name" {
  description = "Optional readable name of the TGW attachment object. It is assigned to the usual AWS Name tag."
  default     = null
  type        = string
}

variable "appliance_mode_support" {
  description = "See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment)."
  default     = "enable"
  type        = string
}

variable "dns_support" {
  description = "See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment)."
  default     = null
  type        = string
}

variable "ipv6_support" {
  description = "See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment)."
  default     = null
  type        = string
}

variable "propagate_routes_to" {
  description = "Map of route propagations from this attachment. Each key is an arbitrary string, each value is the id of a TGW route table which should receive the routes to the attached VPC CIDRs."
  default     = {}
  type        = map(string)
}

variable "transit_gateway_route_table" {
  description = <<-EOF
  TGW's route table which should receive the traffic coming from the `subnet_set` (also called an association). An object with at least two attributes:
  ```
  transit_gateway_route_table = {
    id                 = "tgw-rtb-1234"
    transit_gateway_id = "tgw-1234"
  }
  ```
  EOF
  type = object({
    id                 = string
    transit_gateway_id = string
  })
}

variable "tags" {
  description = "AWS tags to assign to all the created objects."
  default     = {}
  type        = map(string)
}
