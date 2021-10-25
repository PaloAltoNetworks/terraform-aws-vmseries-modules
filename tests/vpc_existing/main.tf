# This Terraform code does not deploy a real-world cloud environment.
# It is a temporary deployment intended solely to perform tests.
# For a quick start see the file main_test.go, which executes the terratest library.
#
# Change this code in the same pull request that changes the main code, e.g. the code inside `modules` directory.
#
# Core tests:
#   - Do various combinations of known inputs produce expected outputs?
#
# Boilerplate tests:
#   - Can we call the module twice?

variable "switchme" {} # unused but required by generictt

data "aws_availability_zones" "this" {
  state = "available"
}

locals {
  az_a = data.aws_availability_zones.this.names[0]
  az_b = data.aws_availability_zones.this.names[1]
  az_c = data.aws_availability_zones.this.names[2]
}

module "vpc" {
  for_each = toset(["test4-vpc1", "test4-vpc2"])
  source   = "../../modules/vpc"

  name                    = each.key
  create_vpc              = true
  create_internet_gateway = true
  create_vpn_gateway      = false
  use_internet_gateway    = false
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = ["10.4.0.0/16", "10.5.0.0/16", "10.6.0.0/16"]
}

module "vpc_noigw" {
  source = "../../modules/vpc"

  name                    = "test4-vpc3"
  create_vpc              = true
  create_internet_gateway = false
  create_vpn_gateway      = false
  use_internet_gateway    = false
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = ["10.4.0.0/16", "10.5.0.0/16", "10.6.0.0/16"]
}

### Reuse Existing Resources ###

module "vpc_data" {
  source = "../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc["test4-vpc1"].name
  create_internet_gateway = false
  use_internet_gateway    = true
}

### Test Results ###

output "is_vpc_cidr_block_correct" {
  value = (module.vpc["test4-vpc1"].vpc.cidr_block == "10.0.0.0/16")
}

output "is_vpc_name_correct" {
  value = (module.vpc["test4-vpc1"].name == "test4-vpc1")
}

output "is_vpc_data_cidr_block_correct" {
  value = (module.vpc_data.vpc.cidr_block == "10.0.0.0/16")
}

output "is_vpc_data_name_correct" {
  value = (module.vpc_data.name == "test4-vpc1")
}
