variable switch {}

data "aws_availability_zones" "this" {
  state = "available"
}

module "vpc" {
  source = "../../modules/vpc"

  create_vpc              = true
  name                    = "test3-vpc3" # TODO use random_id for a minor test: non-static name
  cidr_block              = "10.105.0.0/16"
  availability_zones      = [data.aws_availability_zones.this.names[2], data.aws_availability_zones.this.names[3]] # ["us-east-1c", "us-east-1d"] # FIXME 0.12 Invalid for_each: [data.aws_availability_zones.this.names[2], data.aws_availability_zones.this.names[3]]
  create_internet_gateway = false
  enable_dns_hostnames    = var.switch
  global_tags             = { "Is DNS Enabled" = var.switch }
}

# FIXME 0.12 cannot destroy it:
# Error: Cycle: module.added_subnet_set.aws_subnet.this["d"] (destroy)
# module.existing_vpc.aws_internet_gateway.this[0] (destroy)
# module.added_subnet_set.aws_subnet.this["c"] (destroy)
# module.existing_vpc.data.aws_vpc.this[0] (destroy)
# module.added_subnet_set.var.vpc
# module.added_subnet_set.local.subnets

module "subnet_set" {
  source = "../../modules/subnet_set"

  create_subnet           = true
  name                    = "mgmt-1"
  vpc                     = module.vpc
  cidr_blocks             = ["10.105.0.0/25", "10.105.1.0/25"]
  map_public_ip_on_launch = var.switch
  global_tags             = { "Is Public Mapping Enabled" = var.switch }
}

### Now that we have created resources, reuse them! ###

module "existing_vpc" {
  source = "../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc.name
  availability_zones      = [data.aws_availability_zones.this.names[2], data.aws_availability_zones.this.names[3]]
  create_internet_gateway = true
}

module "existing_subnet_set" {
  source = "../../modules/subnet_set"

  create_subnet         = false
  existing_subnet_names = module.subnet_set.names
  vpc                   = module.existing_vpc # core test: can existing_vpc module report a correct vpc.id
}

module "added_subnet_set" {
  source = "../../modules/subnet_set"

  create_subnet = true
  name          = "added-"
  vpc           = module.existing_vpc
  cidr_blocks   = ["10.105.5.0/25", "10.105.6.0/25"]
}

### Test Results ###

output "is_subnet_cidr_correct" {
  value = (try(module.existing_subnet_set.subnets["c"].cidr_block, null) == "10.105.0.0/25")
}

output "is_subnet_name_correct" {
  value = (try(module.added_subnet_set.names[1], null) == "added-d")
}
