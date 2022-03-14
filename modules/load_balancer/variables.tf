variable "lb_name" {
  description = "Name of the LB to be created"
  type        = string
}

variable "create_application_lb" {
  description = "Determines a type of the LB. For `true` an ALB is created, for `false` (default) - NLB."
  type        = bool
  default     = false
}

variable "internal_lb" {
  description = "Determines if this will be a public facing LB (default) or an internal one."
  type        = bool
  default     = false
}

# variable "subnet_set_name" {
#   description = "A name of the subnet set that this LB should be attached to (name as a key like 'mgmt' or 'trust'). The module will pick up all subnets from all AZs based on this name)"
# }

variable "subnet_set_subnets" {

}

variable "enable_cross_zone_load_balancing" {
  description = "Enable load balancing between instances in different AZs"
  default     = true
}

variable "vpc_id" {
  description = "ID of the security VPC"
}

variable "balance_rules" {
  description = "A map of pairs protocol->port that should be balanced"
}

variable "fw_instance_ips" {

}