variable global_tags {
  type        = map(any)
  description = "A map of tags to add to all resources"
  default     = {}
}

# variable prefix_name_tag {
#   type        = string
#   description = "Prefix used to build name tags for resources"
#   default     = ""
# }

# Panorama version for AMI lookup
variable "panorama_version" {
  description = "Select which Panorama version to deploy"
  default     = "9.1.2"
  # Acceptable Values Below
  #default = "8.1.2"
  #default = "8.1.0"
}

# License type for AMI lookup
variable "pano_license_type" {
  description = "Select License type (byol only for Panorama)"
  default     = "byol"
}

# Product code map based on license type for ami filter
variable "pano_license_type_map" {
  type = map(string)
  default = {
    "byol" = "eclz7j04vu9lf8ont8ta3n17o"
  }
}

# Panorama Deployment Variables
variable "panoramas" {
  type        = any
  description = "Map of Panoramas to be built"
  default     = {}
}

variable subnets_map {
  type        = map(any)
  description = "Map of subnet name to ID, can be passed from remote state output or data source"
  default     = {}
  # Example Format:
  # subnets_map = {
  #   "panorama-mgmt-1a" = "subnet-0e1234567890"
  #   "panorama-mgmt-1b" = "subnet-0e1234567890"
  # } 
}

variable security_groups_map {
  type        = map(any)
  description = "Map of security group name to ID, can be passed from remote state output or data source"
  default     = {}
  # Example Format:
  # security_groups_map = {
  #   "panorama-mgmt-inbound-sg" = "sg-0e1234567890"
  #   "panorama-mgmt-outbound-sg" = "sg-0e1234567890"
  # } 
}