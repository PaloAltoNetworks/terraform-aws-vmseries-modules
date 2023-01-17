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

# Random name allows parallel runs on the same cloud account.
resource "random_pet" "this" {
  prefix = "test-vpc-read"
}

locals {
  vpc_name = random_pet.this.id
}

module "vpc" {
  source = "../../../modules/vpc"

  name                    = local.vpc_name
  create_vpc              = true
  create_internet_gateway = false
  create_vpn_gateway      = true
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = ["10.4.0.0/16", "10.5.0.0/16", "10.6.0.0/16"]
}

### Reuse Existing Resources ###

module "vpc_read" {
  source = "../../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc.name
  create_internet_gateway = false
  use_internet_gateway    = false
}

module "vpc_read_igw_create" {
  source = "../../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc.name
  create_internet_gateway = true
  use_internet_gateway    = false
}

module "vpc_read_igw_read" {
  source = "../../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc_read_igw_create.name
  create_internet_gateway = false
  use_internet_gateway    = true
}
