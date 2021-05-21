### GENERAL SETTINGS
variable "region" {}
variable "prefix_name_tag" {}
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "ssh_key_name" {}
variable "global_tags" {}

### BOOTSTRAP
variable "bootstrap-prefix" {} # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
variable "buckets" {}
variable "init-cfg" {} # tflint-ignore: terraform_naming_convention # TODO rename to snake_case

### VPC
variable "vpcs" {}
variable "route_tables" {}
variable "vpc_subnets" {}
variable "security_groups" {}

### VMSERIES
variable "firewalls" {}
variable "interfaces" {}
