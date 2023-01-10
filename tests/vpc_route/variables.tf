variable "region" {
  description = "AWS region to use for the created resources."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resources created for tests"
  type        = string
}

variable "security_vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
}

variable "security_vpc_subnets" {
  description = "Map of subnets in VPC"
}

variable "security_vpc_security_groups" {
  description = "Map of security groups"
}

variable "security_vpc_mgmt_routes_to_igw" {
  description = "Simple list of CIDR for routes used for management"
}

variable "security_vpc_app_routes_to_igw" {
  description = "Simple list of CIDR for routes used for access application via IGW"
}

variable "security_vpc_app_routes_to_tgw" {
  description = "Simple list of CIDR for routes used for access application via TGW"
}

variable "security_vpc_app_routes_to_natgw" {
  description = "Simple list of CIDR for routes used for access application via NAT gateway"
}

variable "security_vpc_app_routes_to_gwlb" {
  description = "Simple list of CIDR for routes used for access application via NAT gateway"
}

variable "transit_gateway_create" {
  description = "True if create transit gateway with attachment, false in other case"
  type        = bool
}

variable "transit_gateway_name" {
  description = "Transit gateway name"
  type        = string
}

variable "transit_gateway_asn" {
  description = "Transit gateway ASN"
  type        = string
}

variable "transit_gateway_route_tables" {
  description = "Transit gateway route tables"
}

variable "security_vpc_tgw_attachment_name" {
  description = "Transit gateway VPC attachment name"
  type        = string
}

variable "nat_gateway_create" {
  description = "True if create NAT gateway, false in other case"
  type        = bool
}

variable "gwlb_create" {
  description = "True if create GWLB, false in other case"
  type        = bool
}

variable "gwlb_name" {
  description = "Gatewate Load Balancer name"
  type        = string
}

variable "gwlb_endpoint_set_inbound_name" {
  description = "Gatewate Load Balancer endpoint name"
  type        = string
}
