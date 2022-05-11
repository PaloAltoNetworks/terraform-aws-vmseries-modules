### General
variable "region" {}
variable "global_tags" {}
variable "security_vpc_name" {}
variable "security_vpc_cidr" {}
variable "security_vpc_security_groups" {}
variable "gwlb_name" {}
variable "security_vpc_routes_outbound_source_cidrs" {}
variable "security_vpc_routes_outbound_destin_cidrs" {}
variable "gwlb_endpoint_set_outbound_name" {}
variable "security_vpc_subnets" {}
variable "create_ssh_key" {}
variable "ssh_key_name" {}
variable "nat_gateway_name" {}
variable "firewalls" {}
variable "bootstrap_options" {}
