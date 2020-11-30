# Check module for variable definitions and documentation

variable region {
  default = ""
}


variable global_tags {
  type        = map(any)
  description = "A map of tags to add to all resources"
  default     = {}
}

variable panoramas {
  default = {}
}