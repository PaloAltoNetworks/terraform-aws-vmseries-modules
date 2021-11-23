# This Terraform code does not deploy a real-world cloud environment.
# It is a temporary deployment intended solely to perform tests.
# For a quick start see the file main_test.go, which executes the terratest library.
#
# Change this code in the same pull request that changes the code in `modules` directory.
#
# Core tests:
#   - Do various combinations of known inputs produce expected outputs?
#   - Can we discover a pre-existing vpc?
#
# Boilerplate tests:
#   - Can we call the module twice?

variable "switchme" {} # unused but required by generictt

# Random name allows parallel runs on the same cloud account.
resource "random_pet" "this" {
  prefix = "test-vpc-read"
}

locals {
  vpc_name = random_pet.this.id
}

module "vpc" {
  source = "../../modules/vpc"

  name                    = local.vpc_name
  create_vpc              = true
  create_internet_gateway = false
  create_vpn_gateway      = true
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = ["10.4.0.0/16", "10.5.0.0/16", "10.6.0.0/16"]
}

### Reuse Existing Resources ###

module "vpc_read" {
  source = "../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc.name
  create_internet_gateway = false
  use_internet_gateway    = false
}

module "vpc_read_igw_create" {
  source = "../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc.name
  create_internet_gateway = true
  use_internet_gateway    = false
}

module "vpc_read_igw_read" {
  source = "../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc_read_igw_create.name
  create_internet_gateway = false
  use_internet_gateway    = true
}

### Test Results ###

output "is_vpc_cidr_block_correct" {
  value = (module.vpc.vpc.cidr_block == "10.0.0.0/16")
}

output "is_vpc_name_correct" {
  value = (module.vpc.name == local.vpc_name)
}

output "is_vpc_read_cidr_block_correct" {
  value = (module.vpc_read.vpc.cidr_block == "10.0.0.0/16")
}

output "is_vpc_read_name_correct" {
  value = (module.vpc_read.name == local.vpc_name)
}

output "is_vpc_read_igw_create_cidr_block_correct" {
  value = (module.vpc_read_igw_create.vpc.cidr_block == "10.0.0.0/16")
}

output "is_vpc_read_igw_create_name_correct" {
  value = (module.vpc_read_igw_create.name == local.vpc_name)
}

output "is_vpc_read_igw_read_cidr_block_correct" {
  value = (module.vpc_read_igw_read.vpc.cidr_block == "10.0.0.0/16")
}

output "is_vpc_read_igw_read_name_correct" {
  value = (module.vpc_read_igw_read.name == local.vpc_name)
}
