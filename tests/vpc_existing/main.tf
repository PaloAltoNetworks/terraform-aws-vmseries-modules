variable switch {}

module "vpc" {
  source = "../../modules/vpc"

  create_vpc              = true
  name                    = "test3-vpc3" # TODO use random_id for a minor test: non-static name
  cidr_block              = "10.105.0.0/16"
  create_internet_gateway = false
  enable_dns_hostnames    = var.switch
  global_tags             = { "Is DNS Enabled" = var.switch }
}

module "subnet" {
  source = "../../modules/subnet"

  create_subnet           = true
  name                    = "mgmt-1a"
  vpc                     = module.vpc
  cidr_block              = "10.105.0.0/25"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = var.switch
  global_tags             = { "Is Public Mapping Enabled" = var.switch }
}

### Now that we have created resources, reuse them! ###

module "existing_vpc" {
  source = "../../modules/vpc"

  create_vpc              = false
  name                    = module.vpc.name
  create_internet_gateway = true
}

module "existing_subnet" {
  source = "../../modules/subnet"

  create_subnet = false
  vpc           = module.existing_vpc # core test: can existing_vpc module report a correct vpc.id
  name          = module.subnet.name
}

module "added_subnet" {
  source = "../../modules/subnet"

  create_subnet = true
  vpc           = module.existing_vpc
  cidr_block    = "10.105.5.0/25"
}

### Test Results ###

output "is_subnet_cidr_correct" {
  value = (try(module.existing_subnet.subnet.cidr_block, null) == "10.105.0.0/25")
}

output "is_subnet_name_correct" {
  value = (module.added_subnet.name == null)
}
