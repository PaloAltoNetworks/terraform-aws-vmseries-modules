variable "region" {
  default = "us-east-1"
}

variable "global_tags" {
  default = {}
}

variable "security_vpc_name" {
  type = string
}

variable "security_vpc_cidr" {
  type = string
}