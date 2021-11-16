variable "name" { default = null }
variable "cidrs" {}
variable "vpc_id" {}
variable "create_shared_route_table" { default = false }
variable "map_public_ip_on_launch" { default = null }

variable "propagating_vgws" {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)."
  default     = []
  type        = list(string)
}

variable "global_tags" { default = {} }
