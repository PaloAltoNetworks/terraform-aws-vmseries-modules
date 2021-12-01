variable "global_tags" {
  description = "(optional) Map of arbitrary tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix" {
  description = "(optional) The prefix to use for bucket name, IAM role name, and IAM role policy name. It is allowed to use dash \"-\" as the last character."
  default     = "bootstrap-"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "(optional) Name of the instance profile to create. If empty, name will be generated automatically."
  default     = ""
  type        = string
}

variable "force_destroy" {
  description = "Set to false to prevent Terraform from destroying a bucket with unknown objects or locked objects."
  default     = true
  type        = bool
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
