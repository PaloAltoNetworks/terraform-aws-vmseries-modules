### General

variable "region" {
  description = "AWS Region."
  default     = "us-east-1"
  type        = string
}

variable "name_prefix" {
  description = "Prefix use for creating unique names."
  default     = ""
  type        = string
}

variable "name_sufix" {
  description = "Sufix use for creating unique names."
  default     = ""
  type        = string
}

variable "global_tags" {
  description = <<-EOF
  A map of tags to assign to the resources.
  If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  EOF
  default     = {}
  type        = map(any)
}

### Network

variable "security_vpc_cidr" {
  description = "AWS VPC Cidr block."
  type        = string
}

variable "security_vpc_routes_outbound_destin_cidrs" {
  description = "VPC Routes outbound cidr"
  type        = list(string)
}

variable "security_vpc_subnets" {
  description = "Security VPC subnets CIDR"
  default     = {}
  type        = map(any)
}

variable "security_vpc_security_groups" {
  description = <<-EOF
  Security VPC security groups settings.
  Structure looks like this:
  ```
  {
    security_group_name = {
      {
        name = "security_group_name"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }
  }
  ```
  EOF
  type        = map(any)
}

### VM-Series
variable "vmseries" {}
variable "vmseries_version" {}
variable "bootstrap_options" {}
variable "plugin_op_commands" {
  default = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
  type    = string
}
variable "use_s3_bucket_to_bootstrap" {
  default = false
  type    = bool
}
