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
  description = "Simple list of CIDR for routes used for access application"
  default     = ["10.241.0.0/16", "10.242.0.0/16"]
}

locals {
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_mgmt_routes_to_igw :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        cidr_type    = "mpl"
        managed_prefix_list = {
          name        = "${var.name_prefix}mgmt"
          max_entries = 10
          entries = {
            for cidr in concat(var.security_vpc_mgmt_routes_to_igw, var.security_vpc_app_routes_to_igw) : cidr => {
              cidr        = cidr
              description = "CIDR in managed prefix list for MGMT"
            }
          }
        }
      }
    ],
  )
}

resource "random_id" "random_sufix" {
  byte_length = 8
}

module "security_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}${random_id.random_sufix.id}"
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "security_subnet_sets" {
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${try(route.to_cidr, route.managed_prefix_list.name)}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids     = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr             = try(each.value.to_cidr, null)
  cidr_type           = try(each.value.cidr_type, "ipv4")
  managed_prefix_list = try(each.value.managed_prefix_list, null)
  next_hop_set        = each.value.next_hop_set
}

output "destination_cidr_block" {
  value = { for k, v in module.security_vpc_routes : k => v.destination_cidr_block }
}

output "destination_managed_prefix_list_id" {
  value = { for k, v in module.security_vpc_routes : k => v.destination_managed_prefix_list_id }
}

output "destination_managed_prefix_list_entries" {
  value = { for k, v in module.security_vpc_routes : k => v.destination_managed_prefix_list_entries }
}

output "mgmt_test_vpc_route_mgmt_entries" {
  value = flatten([for k, v in module.security_vpc_routes["mgmt_test_vpc_route_mgmt"].destination_managed_prefix_list_entries : v])
}
