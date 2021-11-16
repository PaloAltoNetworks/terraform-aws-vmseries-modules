# Check module for variable definitions and documentation

variable "region" {}

variable "global_tags" {
  description = "Map of tags to add to all resources."
  default     = {}
  type        = map(string)
}

variable "panorama_version" {
  default = "10.0.2"
  type    = string
}

variable "panoramas" {}
