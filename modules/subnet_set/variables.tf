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

variable "has_secondary_cidrs" {
  description = "The input that depends on the secondary CIDR ranges of the VPC `vpc_id`. The actual value (true or false) is ignored, the input is used only to delay subnet creation until the secondary CIDR ranges are processed by Terraform."
  default     = true
  type        = bool
}

variable "global_tags" { default = {} }
