variable "global_tags" {
  description = "Optional Map of arbitrary tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix" {
  default = "bootstrap"
  type    = string
}

variable "iam_instance_profile_name" {
  description = "(optional) Name of the instance profile to create. If empty, name will be generated automatically."
  default     = ""
  type        = string
}

variable "bootstrap_directories" {
  description = "The directories comprising the bootstrap package."
  default = [
    "config/",
    "content/",
    "software/",
    "license/",
    "plugins/"
  ]
}
