# Variable definitions for root module project deployment
# Check readme and variables.tf inside the module for descriptions and documentation

### Global
variable "region" {}
variable "prefix_name_tag" {}
variable "global_tags" {}

### VPC
variable "vpc" {}
variable "subnets" {}
variable "route_tables" {}
variable "security_groups" {}
variable "routes" {}

### LOAD BALANCER
variable "nlbs" {}
