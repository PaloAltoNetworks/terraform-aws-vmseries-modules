variable "region" {
  description = "AWS region to use for the created resources."
  default     = "us-east-1"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resources created for tests"
  default     = "test_vpc_route_"
  type        = string
}

variable "security_vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.100.0.0/16"
  type        = string
}

variable "security_vpc_subnets" {
  description = "Map of subnets in VPC"
  default = {
    "10.100.0.0/24" = { az = "us-east-1a", set = "mgmt" }
    "10.100.1.0/24" = { az = "us-east-1a", set = "tgw_attach" }
  }
}

variable "security_vpc_security_groups" {
  description = "Map of security groups"
  default = {
    vmseries_mgmt = {
      name = "vmseries_mgmt"
      rules = {
        all_outbound = {
          description = "Permit ALL outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ssh = {
          description = "Permit SSH inbound"
          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}

variable "security_vpc_mgmt_routes_to_igw" {
  description = "Simple list of CIDR for routes used for management"
  default     = ["10.251.0.0/16", "10.252.0.0/16"]
}

variable "security_vpc_app_routes_to_igw" {
  description = "Simple list of CIDR for routes used for access application via IGW"
  default     = ["10.241.0.0/16", "10.242.0.0/16"]
}

variable "security_vpc_app_routes_to_tgw" {
  description = "Simple list of CIDR for routes used for access application via TGW"
  default     = ["10.231.0.0/16", "10.232.0.0/16"]
}

variable "transit_gateway_name" {
  default = "tgw"
}

variable "transit_gateway_asn" {
  default = "65200"
}

variable "transit_gateway_route_tables" {
  default = {
    "from_security_vpc" = {
      create = true
      name   = "from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
}

variable "security_vpc_tgw_attachment_name" {
  default = "tgw"
}
