variable "region" {
  description = "AWS region to use for the created resources."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resources created for tests"
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
  default     = { }
}
