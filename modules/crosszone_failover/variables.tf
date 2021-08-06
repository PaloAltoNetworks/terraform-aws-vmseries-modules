variable "subnet_state" {
  description = "Exported state from base VPC workspace to map resource names to IDs."
}

variable "sg_state" {
  description = "Exported state from base infra workspace to make SG names to IDs."
}

variable "vpc_id" {
  description = "VPC ID."
}

variable "region" {
  description = "AWS Region."
}

variable "tags" {
  description = "Map of additional tags to apply to all resources."
  type        = map(any)
  default     = {}
}

variable "prefix_name_tag" {
  description = "Prefix used to build name tags for resources."
  default     = ""
  type        = string
}

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
