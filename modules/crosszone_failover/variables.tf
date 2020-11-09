variable "subnet_state" {
  description = "Exported state from base VPC workspace to map resource names to IDs"
}

variable "sg_state" {
  description = "Exported state from base infra workspace to make SG names to IDs"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "region" {
  description = "AWS Region"
}

variable "tags" {
  description = "Map of additional tags to apply to all resources"
  type        = map
  default     = {}
}

variable prefix_name_tag {
  type        = string
  default     = ""
  description = "Prefix used to build name tags for resources"
}

variable lambda_s3_bucket {
  type        = string
  default     = ""
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