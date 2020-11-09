variable region {
  description = "AWS region for provider"
  type        = string
  default     = ""
}

variable prefix_name_tag {
  description = "Prepended to name tags for various resources. Leave as empty string if not desired."
  type        = string
  default     = ""
}

variable global_tags {
  description = "Optional Map of arbitrary tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable vpcs {
  description = "Map of Existing VPC Names to IDs. Used for TGW attachments."
  type        = any
  default     = {}
}

variable subnets {
  description = "Map of Existing Subnet Names to IDs. Used for TGW attachments."
  type        = any
  default     = {}
}

variable transit_gateways {
  type        = any
  default     = {}
  description = "Nested Map of TGWs and their attributes (Brownfield Supported)"
}

variable transit_gateway_vpc_attachments {
  type        = map(any)
  description = "Map of attachments to create and RT to associate / propagate to"
  default     = {}
}

variable transit_gateway_peerings {
  type        = map(any)
  description = "Map of parameters to peer TGWs with cross-region / cross-account existing TGW"
  default     = {}
}

variable transit_gateway_peer_region {
  type        = string
  description = "Region for alias provider for Transit Gateway Peering"
  default     = ""
}


