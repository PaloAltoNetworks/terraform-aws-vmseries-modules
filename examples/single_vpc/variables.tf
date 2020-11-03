# Check module for variable definitions and documentation

variable region {
  default = ""
}

variable prefix_name_tag {
  default = ""
}

variable global_tags {
  default = {}
}

variable vpc {
  default = {}
}

variable vpc_route_tables {
  default = {}
}

variable subnets {
  default = {}
}

variable nat_gateways {
  default = {}
}

variable vpn_gateways {
  default = {}
}

variable vpc_endpoints {
  default = {}
}

variable security_groups {
  default = {}
}

variable vpc_routes {
  default = {}
}


variable "interfaces" {}
variable "ssh_key_name" {}
variable "firewalls" {
  default = {}
}
variable "fw_license_type" {}
variable "fw_version" {}
variable "fw_instance_type" {}
variable "addtional_interfaces" {
  default = {}
}
