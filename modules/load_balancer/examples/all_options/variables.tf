# Variable definitions for root module project deployment
# Check readme and variables.tf inside the module for descriptions and documentation

# AWS Variables
variable "region" { default = "" }
variable "vpc_id" { default = "" }
variable "target_instance_ids" { default = [] }
variable "elb_subnet_ids" { default = [] }
variable "global_tags" { default = {} }
variable "nlbs" { default = {} }
variable "albs" { default = {} }


