variable "region" {
  description = "AWS Region"
}

variable "global_tags" {
  description = "Map of additional tags to apply to all resources"
  type        = map
  default     = {}
}

variable prefix_name_tag {
  type        = string
  default     = ""
  description = "Prefix used to build name tags for resources"
}

variable subnets_map {
  type        = map(any)
  description = "Map of subnet name to ID, can be passed from remote state output or data source"
  default     = {}
  # Example Format:
  # subnets_map = {
  #   "panorama-mgmt-1a" = "subnet-0e1234567890"
  #   "panorama-mgmt-1b" = "subnet-0e1234567890"
  # } 
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
  type        = list
  default     = []
  description = "Map of principals allowed to use enpoint service"
}

variable "gateway_load_balancers" {}
variable "gateway_load_balancer_endpoints" {}