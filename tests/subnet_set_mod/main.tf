# This Terraform code does not deploy a real-world cloud environment.
# It is a temporary deployment intended solely to perform tests.
# For a quick start see the file main_test.go, which executes the terratest library.
#
# Change this code in the same pull request that changes the code in `modules` directory.
#
# Core tests:
#   - Can we add a subnet to the set without disrupting the existing traffic?

variable "switchme" {
  description = "The true/false switch for testing the modifiability. Initial runs should use `true`, then at some point one or more consecutive runs should use `false` instead."
  type        = bool
}

# Random name allows parallel runs on the same cloud account.
resource "random_pet" "this" {
  prefix = "test-ss-mod"
}

locals {
  vpc_name = random_pet.this.id
}

module "vpc" {
  source = "../../modules/vpc"

  name                    = local.vpc_name
  create_internet_gateway = false
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = var.switchme ? ["10.4.0.0/16"] : ["10.4.0.0/16", "10.5.0.0/16"]
}

module "subnet_set" {
  source = "../../modules/subnet_set"

  name                = local.vpc_name
  vpc_id              = module.vpc.id
  has_secondary_cidrs = module.vpc.has_secondary_cidrs
  cidrs = var.switchme ? {
    "10.0.0.0/24" = { az = "us-east-1a" }
    "10.4.0.0/24" = { az = "us-east-1b" }
    } : {
    "10.0.0.0/24" = { az = "us-east-1a" }
    "10.4.0.0/24" = { az = "us-east-1b" }
    "10.5.0.0/24" = { az = "us-east-1c" }
  }
}
