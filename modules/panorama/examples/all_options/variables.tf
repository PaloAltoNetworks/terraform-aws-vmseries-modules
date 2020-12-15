# Check module for variable definitions and documentation

variable region {
  default = ""
}

variable global_tags {
  type        = map(any)
  description = "A map of tags to add to all resources"
  default     = {}
}

variable panorama_version {
  type    = string
  default = "10.0.2"
}

variable panoramas {}
