module "vpc" {
  source = "../../modules/vpc"

  create_vpc              = true
  name                    = "example2-vpc"
  availability_zones      = ["us-east-1a", "us-east-1b"]
  cidr_block              = "10.100.0.0/16"
  secondary_cidr_blocks   = ["10.200.0.0/16", "10.201.0.0/16"]
  create_internet_gateway = true
  create_vpn_gateway      = true
  global_tags             = var.global_tags
  security_groups         = var.security_groups # Needed only for apigw-endpoint.
}

module "subnet_public" {
  source = "../../modules/subnet_set"

  name                  = "public-1"
  vpc                   = module.vpc
  cidr_blocks           = ["10.100.0.0/25", "10.100.64.0/25"]
  create_route_table    = true
  create_nat_gateway    = true
  propagate_routes_from = { myvpn = module.vpc.vpn_gateway.id /* Optionally also a Detached VGW (that is, one not parented by a VPC). */ }

  routes = {
    mgmt-igw = {
      prefix        = "0.0.0.0/0"
      next_hop_type = "internet_gateway"
    }
    # FIXME nat_gateway
  }
  vpc_endpoints = {
    apigw-endpoint = {
      create             = true
      name               = "apigw-endpoint"
      service_name       = "com.amazonaws.us-east-1.execute-api"
      vpc_endpoint_type  = "Interface"
      security_group_ids = [module.vpc.security_group_ids["vpc-endpoint"]]
    }
    s3-endpoint = {
      create            = true
      name              = "s3-endpoint"
      service_name      = "com.amazonaws.us-east-1.s3"
      vpc_endpoint_type = "Gateway"
    }
  }
}
