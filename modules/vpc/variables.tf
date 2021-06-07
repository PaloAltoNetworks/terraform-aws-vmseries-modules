variable region {
  description = "AWS Region for deployment, for example \"us-east-1\"."
  default     = ""
  type        = string
}

variable prefix_name_tag {
  description = "Prepend a string to Name tags for the created resources. Can be empty."
  default     = ""
  type        = string
}

variable global_tags {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}

variable security_groups {
  description = "Map of AWS Security Groups."
  default     = {}
  type        = any
}

variable name { default = null }
variable create_vpc { default = true }
variable cidr_block { default = null }
variable secondary_cidr_blocks { default = [] }
variable create_internet_gateway { default = null }
variable enable_dns_support { default = null }
variable enable_dns_hostnames { default = null }
variable instance_tenancy { default = null }
variable assign_generated_ipv6_cidr_block { default = null }
variable create_vpn_gateway { default = false }
variable vpn_gateway_amazon_side_asn { default = null }
variable create_nat_gateway { default = false }
variable vpc_tags { default = {} }
