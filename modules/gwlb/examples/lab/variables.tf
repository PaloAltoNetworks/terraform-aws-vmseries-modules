### Global
variable "region" {}
variable "prefix_name_tag" {}
variable "global_tags" {}
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "ssh_key_name" {}


### inbound/outbound
variable "north-south_vpc" {}
variable "north-south_vpc_route_tables" {}
variable "north-south_vpc_subnets" {}
variable "north-south_vpc_security_groups" {}
variable "north-south_interfaces" {}
variable "north-south_firewalls" {}
variable "north-south_addtional_interfaces" {}
variable "north-south_nat_gateways" {}
variable "north-south_vpc_endpoints" {}
variable "north-south_vpc_routes" {}




variable "gwlb_subnets" {}