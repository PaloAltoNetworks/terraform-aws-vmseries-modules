variable "region" {
  description = "AWS Region"
}

variable "tags" {
  description = "Map of additional tags to apply to all resources"
  type        = map
  default     = {}
}

variable prefix_name_tag {
  type        = string
  default     = ""
  description = "Prefix used to build name tags for resources"
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "firewalls" {
  type        = map
  description = "(optional) Map of firewalls that will be attached to target group"
  default     = {}
}

variable "subnet_ids" {
  type        = list
  description = "A list of subnet IDs to attach to the Load Balancer"
}

variable "allowed_principals" {
  type = list
  default = []
  description = "Map of principals allowed to use enpoint service"
}