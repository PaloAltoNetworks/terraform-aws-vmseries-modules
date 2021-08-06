variable "base_infra_state_bucket" {
  description = "Name of S3 bucket containing remote state for base infra."
}

variable "base_infra_state_key" {
  description = "Name of key for remote state for base infra."
}

variable "base_infra_region" {
  description = "Region for remote state for base infra."
}

variable "region" {
  description = "AWS Region."
}

variable "tags" {
  description = "Map of additional tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix_name_tag" {
  description = "Prefix used to build name tags for resources"
  default     = ""
  type        = string
}

variable "shared_cred_file" {} # TODO: remove the remote state (TERRAM-116)

variable "shared_cred_profile" {}

variable "lambda_s3_bucket" {
  description = "Name of bucket with lambda zip package to deploy."
  default     = ""
  type        = string
}

variable "lambda_file_location" {
  description = "Name of folder where lambda package is stored in this workspace."
  default     = "lambda-package"
  type        = string
}

variable "lambda_file_name" {
  description = "File name of lambda package."
  default     = "crosszone_ha_instance_id.zip"
  type        = string
}
