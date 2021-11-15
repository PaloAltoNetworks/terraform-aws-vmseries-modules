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

variable "source_root_directory" {
  description = "The source directory to become the bucket's root directory. If empty uses `files` subdirectory of a Terraform configuration root directory."
  default     = ""
  type        = string
}

variable "bootstrap_directories" {
  description = "The standard directories which are always created on the bucket, even if not present inside the `source_root_directory`."
  default = [
    "config/",
    "content/",
    "software/",
    "license/",
    "plugins/"
  ]
  type = list(string)
}
