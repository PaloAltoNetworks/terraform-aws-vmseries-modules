variable prefix_name_tag {
  type        = string
  default     = ""
  description = "Prepended to name tags for various resources. Leave as empty string if not desired."
}

variable global_tags {
  description = "Optional Map of arbitrary tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable vpc_routes {
  description = "Map of Routes to create."
  type        = any
  default     = {}
}

variable vpc_route_tables {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}

variable internet_gateways {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}

variable vpn_gateways {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}

variable nat_gateways {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}

variable transit_gateways {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}

variable vpc_peers {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}

variable interfaces {
  description = "Map of Route Table Names to IDs."
  type        = any
  default     = {}
}
