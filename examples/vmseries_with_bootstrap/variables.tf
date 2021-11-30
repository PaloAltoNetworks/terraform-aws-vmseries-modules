### GLOBAL
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



### VPC
variable "cidr_block" {
  type = string
}

variable "security_groups" {
  default = {}
  type    = map(any)
}



### SUBNET_SET
variable "subnets" {
  default = {}
}



### VMSERIES
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "ssh_key_name" {}
variable "interfaces" {}
variable "firewalls" {}
