variable region {
  type        = string
  default     = ""
  description = "AWS Region for deployment"
}

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

variable vpc {
  description = "Map of parameters for the VPC."
  type        = any
  default     = {}
}

variable vpc_route_tables {
  type        = any
  description = "Map of VPC route Tables to create"
  default     = {}
}

variable subnets {
  description = "Map of Subnets to create"
  type        = any
  default     = {}
}

variable nat_gateways {
  type        = any
  description = "Map of NAT Gateways to create"
  default     = {}
}

variable vpn_gateways {
  type        = any
  description = "Map of VGWs to create"
  default     = {}
}

variable vpc_endpoints {
  type        = any
  description = "Map of VPC endpoints"
  default     = {}
}

variable security_groups {
  type        = any
  description = "Map of Security Groups"
  default     = {}
}


### Testing concept of explicit schema for map vars

# variable vpc {
#   description = "Parameters for the VPC"
#   type        = map(object({
#     name = string
#     cidr_block = string
#     secondary_cidr_blocks = list(string)
#     tenancy = string
#     igw = bool
#   }))
#   default     = {}
# }

# variable subnets {
#   description = "Map of subnets to create in the vpc."
#   type        = map(object({
#     existing = bool
#     name = string
#     cidr = string
#     az = string
#     rt = string
#   }))
#   default     = {}
# }