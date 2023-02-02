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

variable "security_vpc_app_routes" {
  description = "Simple list of CIDR for routes used in security VPC"
  default     = []
}

variable "security_vpc_tgw_attachment_name" {
  description = "Transit gateway VPC attachment name"
  default     = null
  type        = string
}

variable "transit_gateway_name" {
  description = "Transit gateway name"
  default     = null
  type        = string
}

variable "transit_gateway_asn" {
  description = "Transit gateway ASN"
  default     = null
  type        = string
}

variable "transit_gateway_route_tables" {
  description = "Transit gateway route tables"
  default     = {}
}
