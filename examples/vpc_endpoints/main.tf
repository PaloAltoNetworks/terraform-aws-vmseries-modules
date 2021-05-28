module "vpc" {
  source = "../../modules/vpc"

  create_vpc              = true
  name                    = "example2-vpc"
  cidr_block              = "10.100.0.0/16"
  secondary_cidr_blocks   = ["10.200.0.0/16", "10.201.0.0/16"]
  create_internet_gateway = true
  create_vpn_gateway      = true
  global_tags             = var.global_tags
}

module "subnet" {
  source = "../../modules/subnet"

  name                  = "mgmt-1a"
  vpc                   = module.vpc
  cidr_block            = "10.100.0.0/25"
  availability_zone     = "us-east-1a"
  create_route_table    = true
  propagate_routes_from = { myvpn = module.vpc.vpn_gateway.id /* Optionally also a Detached VGW (that is, not parented by a VPC). */ }

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
