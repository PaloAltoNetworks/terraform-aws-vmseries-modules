variable "name" {
  description = "Subnet set name, used to construct default subnet names."
  default     = null
  type        = string
}

variable "cidrs" {
  description = <<-EOF
  Map describing configuration of subnets and route tables to create and/or use in the set.
  Keys are CIDR blocks, values can consist of following items:
  - `create_subnet`           - (Optional|bool) When `true` (default), subnet is created, otherwise existing one is used.
  - `create_route_table`      - (Optional|bool) When `true`  a dedicated route table is created, unless existing subnet is used.
  - `associate_route_table`   - (Optional|bool) Unless set to `false`, route table is associated with the subnet.
  - `existing_route_table_id` - (Optional|string) Id of an existing route table to associate with the subnet.
  - `name`                    - (Optional|string) Name (tag) of a subnet and, optionally a route table, to create or use. Defaults to set name appended with zone letter id.
  - `route_table_name`        - (Optional|string) Name (tag) of a subnet and, optionally a route table, to create or use.  Defaults to `name` value.
  - `local_tags`              - (Optional|map) Map of tags to assign to created resources.
  EOF
  type        = map(any)
}

variable "vpc_id" {
  description = "Id of the VPC to create resource in."
  type        = string
}

variable "create_shared_route_table" {
  description = "Boolean flag whether to create a shared route tables."
  default     = false
  type        = bool
}

variable "map_public_ip_on_launch" {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet#map_public_ip_on_launch)."
  default     = null
  type        = bool
}

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

variable "global_tags" {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}
