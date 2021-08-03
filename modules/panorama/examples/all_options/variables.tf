# Check module for variable definitions and documentation

variable "region" {}

variable "global_tags" {}

variable "panorama_version" {
  type    = string
  default = "10.0.2"
}

variable "panoramas" {}
