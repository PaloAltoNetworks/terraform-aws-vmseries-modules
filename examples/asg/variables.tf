#Global
variable "region" {}
variable "name_prefix" {}
variable "global_tags" {}

#VPC
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "vpc_security_groups" {}
variable "vpc_subnets" {}
variable "security_vpc_routes_outbound_destin_cidrs" {}

#ASG
variable "asg_max_size" {}
variable "asg_min_size" {}
variable "asg_desired_cap" {}

#VM-Series
variable "bootstrap_options" {}
variable "ssh_key_name" {}
variable "vmseries_interfaces" {}
variable "vmseries_version" {}
