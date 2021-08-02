variable "region" {
  description = "AWS region for provider."
  default     = ""
  type        = string
}

variable "prefix_name_tag" {
  description = "Prepended to name tags for various resources. Leave as empty string if not desired."
  default     = ""
  type        = string
}

variable "global_tags" {
  description = "Optional Map of arbitrary tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "vpcs" {
  description = "Map of Existing VPC Names to IDs. Used for TGW attachments."
  default     = {}
  type        = map(any)
}

variable "subnets" {
  description = "Map of Existing Subnet Names to IDs. Used for TGW attachments."
  default     = {}
  type        = map(any)
}

variable "transit_gateways" {
  description = "Nested Map of TGWs and their attributes (Brownfield Supported)."
  default     = {}
  type        = map(any)
}

variable "transit_gateway_vpc_attachments" {
  description = "Map of attachments to create and RT to associate / propagate to."
  default     = {}
  type        = map(any)
}

variable "transit_gateway_peerings" {
  description = "Map of parameters to peer TGWs with cross-region / cross-account existing TGW."
  default     = {}
  type        = map(any)
}

variable "transit_gateway_peer_region" {
  description = "Region for alias provider for Transit Gateway Peering."
  default     = ""
  type        = string
}


