variable "region" {
  description = "AWS Region."
}

variable "global_tags" {
  description = "Map of additional tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix_name_tag" {
  description = "Prefix used to build name tags for resources."
  default     = ""
  type        = string
}

variable "subnets_map" {
  description = <<-EOF
  Map of subnet name to ID, can be passed from remote state output or data source.

  Example:

  ```
  subnets_map = {
    "panorama-mgmt-1a" = "subnet-0e1234567890"
    "panorama-mgmt-1b" = "subnet-0e1234567890"
  }
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "firewalls" {
  description = "(optional) Map of firewalls that will be attached to target group."
  default     = {}
  type        = map(any)
}

variable "subnet_ids" {
  description = "A list of subnet IDs to attach to the Load Balancer."
  type        = list(any)
}

variable "allowed_principals" {
  description = "Map of principals allowed to use enpoint service."
  default     = []
  type        = list(any)
}

variable "gateway_load_balancers" {}
variable "gateway_load_balancer_endpoints" {}
