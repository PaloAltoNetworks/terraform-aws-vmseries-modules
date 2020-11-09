variable global_tags {
  type        = map(any)
  description = "A map of tags to add to all resources"
  default     = {}
}

variable prefix_name_tag {
  type        = string
  description = "Prefix used to build name tags for resources"
  default     = ""
}

variable "panoramas" {
  default = {}
}

variable subnets_map {
  default = {}
}

variable security_groups_map {
  default = {}
}