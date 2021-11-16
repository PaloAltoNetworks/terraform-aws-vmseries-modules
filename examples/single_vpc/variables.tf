# Check module for variable definitions and documentation

variable "region" {
  description = "AWS Region for deployment, for example \"us-east-1\"."
  default     = ""
  type        = string
}

variable "prefix_name_tag" {
  description = "Prepend a string to Name tags for the created resources. Can be empty."
  default     = ""
  type        = string
}

variable "global_tags" {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}

variable "vpc_tags" {
  description = "Optional map of arbitrary tags to apply to the created VPC resource, in addition to the `global_tags`."
  default     = {}
  type        = map(string)
}

variable "vpc_cidr_block" {}

variable "vpc_secondary_cidr_blocks" { default = [] }

variable "igw_routing_destination_cidr" {
  description = "The destination CIDR that matches traffic from the deployed VPC towards the Internet Gateway."
  default     = "0.0.0.0/0"
  type        = string
}

variable "subnets" {
  default = {}
}

variable "security_groups" {
  default = {}
}

variable "interfaces" {}
variable "ssh_key_name" {}
variable "firewalls" {
  default = {}
}
variable "fw_license_type" {}
variable "fw_version" {}
variable "fw_instance_type" {}
variable "addtional_interfaces" {
  default = {}
}
