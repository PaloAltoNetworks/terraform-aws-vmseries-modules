# Check module for variable definitions and documentation

variable "region" {}

variable "global_tags" {
  description = "Map of tags to add to all resources."
  default     = {}
  type        = map(string)
}

variable "panorama_version" {
  type    = string
  default = "10.0.2"
}

variable "panoramas" {}
