resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  vpc_id                                          = var.subnet_set.vpc_id
  subnet_ids                                      = [for _, subnet in var.subnet_set.subnets : subnet.id]
  transit_gateway_id                              = var.transit_gateway_route_table.transit_gateway_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = var.appliance_mode_support
  dns_support                                     = var.dns_support
  ipv6_support                                    = var.ipv6_support
  tags                                            = merge(var.tags, var.name != null ? { Name = var.name } : {})
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.transit_gateway_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = var.propagate_routes_to

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = each.value
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
  TGW's route table which should receive the traffic coming from the `subnet_set` (also called an association). An object with two attributes:
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

variable "subnet_set" {
  description = <<-EOF
  The attachment's subnet set, such as a result of a call to the module `subnet_set`.
  All subnets of the set obtain virtual network interfaces attached to the TGW.
  The input does not support multiple subnet sets. Example: `subnet_set = module.my_subnet_set`
  EOF
  type = object({
    vpc_id = string
    subnets = map(object({
      id = string
    }))
  })
}

variable "tags" {
  description = "AWS tags to assign to all the created objects."
  default     = {}
  type        = map(string)
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

output "attachment" {
  description = "The entire `aws_ec2_transit_gateway_vpc_attachment` object."
  value       = aws_ec2_transit_gateway_vpc_attachment.this
}

output "subnet_set" {
  description = "Same as the input `subnet_set`. Intended to be used as a dependency."
  value       = contains(aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids, "!") == false ? var.subnet_set : null
}

output "next_hop_set" {
  value = {
    type = "transit_gateway"
    id   = aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_id
    ids  = {}
  }
}
