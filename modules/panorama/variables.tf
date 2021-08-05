variable "global_tags" {
  description = "A map of tags to add to all resources."
  default     = {}
  type        = map(any)
}

# Panorama version for AMI lookup
variable "panorama_version" {
  description = "Panorama version to deploy. For example: \"8.1.2\"."
  default     = "10.0.2"
  type        = string

}

# License type for AMI lookup
variable "pano_license_type" {
  description = "Select License type (byol only for Panorama)"
  default     = "byol"
  type        = string
}

# Product code map based on license type for ami filter
variable "pano_license_type_map" {
  description = <<-EOF
  Map of Panorama licence types and corresponding Panorama Amazon Machine Image (AMI) ID.
  The key is the licence type, and the value is the Panorama AMI ID."
  EOF
  default = {
    "byol" = "eclz7j04vu9lf8ont8ta3n17o"
  }
  type = map(string)
}

# Panorama Deployment Variables
variable "panoramas" {
  description = "Map of Panoramas to be built."
  default     = {}
  type        = any
}

variable "subnets_map" {
  description = <<-EOF
  Map of subnet name to ID, can be passed from remote state output or data source.
  
  Example:

  ```
  subnets_map = {
    "panorama-mgmt-1a" = "subnet-0e1234567890"
    "panorama-mgmt-1b" = "subnet-0e1234567890"
  }
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "security_groups_map" {
  description = <<-EOF
  Map of security group name to ID, can be passed from remote state output or data source.

  Example:

  ```
  security_groups_map = {
    "panorama-mgmt-inbound-sg" = "sg-0e1234567890"
    "panorama-mgmt-outbound-sg" = "sg-0e1234567890"
  } 
  ```
  EOF
  default     = {}
  type        = map(any)
}
