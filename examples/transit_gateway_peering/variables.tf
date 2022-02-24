variable "region" {
  description = "The AWS region where to create local resources."
  type        = string
}

variable "remote_region" {
  description = "The AWS region where to create remote resources."
  type        = string
}

variable "prefix_name_tag" {
  description = "Prefix for the AWS Name tags of all the created resources."
  default     = ""
  type        = string
}
