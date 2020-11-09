variable "base_infra_state_bucket" {
    description = "Name of S3 bucket containing remote state for base infra"
}

variable "base_infra_state_key" {
    description = "Name of key for remote state for base infra"
}

variable "base_infra_region" {
    description = "Region for remote state for base infra"
}

variable "region" {
  description = "AWS Region"
}

variable "tags" {
  description = "Map of additional tags to apply to all resources"
  type = map
  default = {}
}

variable prefix_name_tag {
  type        = string
  default     = ""
  description = "Prefix used to build name tags for resources"
}

variable "shared_cred_file" {}
variable "shared_cred_profile" {}

variable lambda_s3_bucket {
  type = string
  default = ""
  description = "Name of bucket with lambda zip package to deploy"
}

variable lambda_file_location {
  type        = string
  default     = "lambda-package"
  description = "Name of folder where lambda package is stored in this workspace"
}

variable lambda_file_name {
  type        = string
  default     = "crosszone_ha_instance_id.zip"
  description = "File name of lambda package"
}
