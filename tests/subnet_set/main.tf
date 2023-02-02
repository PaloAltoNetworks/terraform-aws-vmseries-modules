resource "random_pet" "this" {
  prefix = "test-subnet-set"
}

locals {
  vpc_name = random_pet.this.id
}

module "vpc" {
  source = "../../modules/vpc"

  name                    = local.vpc_name
  create_internet_gateway = false
  cidr_block              = "10.0.0.0/16"
  secondary_cidr_blocks   = ["10.4.0.0/16"]
}

module "subnet_set" {
  source = "../../modules/subnet_set"

  name                = local.vpc_name
  vpc_id              = module.vpc.id
  has_secondary_cidrs = module.vpc.has_secondary_cidrs
  cidrs = {
    "10.0.0.0/24" = { az = "us-east-1a" }
    "10.4.0.0/24" = { az = "us-east-1b" }
  }
}
