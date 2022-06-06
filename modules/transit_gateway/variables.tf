variable "create" {
  default = true
}

variable "name" {
  description = "Name tag for the Transit Gateway and associated resources."
  type        = string
}
variable "id" {
  description = "ID of an existing Transit Gateway. Used in conjunction with `create = false`. When set, takes precedence over `var.name`."
  default     = null
  type        = string
}

variable "asn" {
  description = "BGP Autonomous System Number of the AWS Transit Gateway."
  default     = 65200
}

variable "auto_accept_shared_attachments" {
  description = "See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway)."
  default     = null
  type        = string
}

variable "dns_support" {
  description = "See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway)."
  default     = null
  type        = string
}

variable "vpn_ecmp_support" {
  description = "See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway)."
  default     = null
  type        = string
}

variable "route_tables" {
  default = {}
}

variable "ram_resource_share_name" {
  default = null
}

variable "shared_principals" {
  default = {}
}

variable "tags" {
  description = "Optional Map of arbitrary tags to apply to all resources"
  type        = map(string)
  default     = {}
}
