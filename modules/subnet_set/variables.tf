variable name { default = null }
variable cidrs {}
variable prefix_name_tag { default = "prefix-" }
variable create_shared_route_table { default = false }
variable global_tags { default = {} }
variable map_public_ip_on_launch { default = null }
variable vpc_id {}

variable propagating_vgws {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)."
  default     = []
  type        = list(string)
}
