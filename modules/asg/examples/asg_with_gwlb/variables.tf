### GENERAL SETTINGS
variable "region" {}
variable "prefix_name_tag" {}
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "ssh_key_name" {}
variable "global_tags" {}

### VPC
variable "vpcs" {}
variable "route_tables" {}
variable "vpc_subnets" {}
variable "security_groups" {}

### ASG
variable "interfaces" {}
variable "bootstrap_options" {}

### GWLB
variable "gateway_load_balancer_subnets" {}
variable "gateway_load_balancers" {}
variable "gateway_load_balancer_endpoints" {}