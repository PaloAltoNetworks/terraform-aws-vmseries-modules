variable "region" {
  description = "The AWS region where to create local resources."
  type        = string
}

variable "remote_region" {
  description = "The AWS region where to create remote resources."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resources created for tests"
  type        = string
}

variable "local_transit_gateway_name" {
  description = "Transit gateway name"
  default     = null
  type        = string
}

variable "local_transit_gateway_asn" {
  description = "Transit gateway ASN"
  default     = null
  type        = string
}

variable "remote_transit_gateway_name" {
  description = "Transit gateway name"
  default     = null
  type        = string
}

variable "remote_transit_gateway_asn" {
  description = "Transit gateway ASN"
  default     = null
  type        = string
}
