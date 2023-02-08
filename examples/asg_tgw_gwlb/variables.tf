#Global
variable "region" {}
variable "name_prefix" {}
variable "global_tags" {}
variable "ssh_public_key_path" {}

#VPC
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "vpc_security_groups" {}
variable "vpc_subnets" {}
variable "security_vpc_routes_outbound_destin_cidrs" {}
variable "security_vpc_routes_outbound_source_cidrs" {}
variable "security_vpc_routes_eastwest_cidrs" {}
variable "security_vpc_mgmt_routes_to_tgw" {}


#ASG
variable "asg_max_size" {}
variable "asg_min_size" {}
variable "asg_desired_cap" {}
variable "asg_instance_type" {}

#VM-Series
variable "bootstrap_options" {}
variable "ssh_key_name" {}
variable "vmseries_interfaces" {}
variable "vmseries_version" {}

##TGW
variable "transit_gateway_id" {}
variable "transit_gateway_route_tables" {}

##GWLB
variable "gwlb_name" {}
variable "gwlb_endpoint_set_outbound_name" {}
variable "gwlb_endpoint_set_eastwest_name" {}
variable "security_vpc_tgw_attachment_name" {}
