### GENERAL SETTINGS
variable "region" {}
variable "prefix_name_tag" {}
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "ssh_key_name" {}
variable "global_tags" {}

### BOOTSTRAP
variable "bootstrap_prefix" {}
variable "buckets" {}
variable "init_cfg" {}

### VPC
variable "vpcs" {}
variable "route_tables" {}
variable "vpc_subnets" {}
variable "security_groups" {}

### VMSERIES
variable "firewalls" {}
variable "interfaces" {}
