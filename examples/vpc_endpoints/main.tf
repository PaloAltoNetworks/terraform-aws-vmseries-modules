module "vpc" {
  source = "../../modules/vpc"

  global_tags     = var.global_tags
  prefix_name_tag = var.prefix_name_tag


  create_vpc            = true
  name                  = "jb10-vpc"
  cidr_block            = "10.100.0.0/16"
  secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]


  # enable_dns_support    = var.vpc.enable_dns_support
  # enable_dns_hostnames  = var.vpc.enable_dns_hostnames
  # instance_tenancy      = var.vpc.instance_tenancy

  create_internet_gateway = true


  # vpc_route_tables = var.vpc_route_tables
  # subnets          = var.subnets
  # nat_gateways     = var.nat_gateways
  # vpn_gateways     = var.vpn_gateways
  # vpc_endpoints    = var.vpc_endpoints
  # security_groups  = var.security_groups
}

module "subnet_mgmt" {
  source = "../../modules/subnet"

  name               = "mgmt-1a"
  vpc                = module.vpc
  cidr_block         = "10.100.0.0/25"
  availability_zone  = "us-east-1a"
  create_route_table = true
  routes = {
    mgmt-igw = {
      prefix        = "0.0.0.0/0"
      next_hop_type = "internet_gateway"
    }
  }
  vpc_endpoints = {
    s3-endpoint = {
      name              = "s3-endpoint"
      service_name      = "com.amazonaws.us-east-1.s3"
      vpc_endpoint_type = "Gateway"
    }
  }
}
