
module "vpc" {
  source = "../../modules/vpc"

  name                    = "${var.prefix_name_tag}vpc"
  cidr_block              = "10.100.0.0/16"
  create_internet_gateway = false
  global_tags             = var.global_tags
  security_groups = {
    vpc_endpoint = {
      name       = "vpc_endpoint"
      local_tags = { "foo" = "bar" }
      rules = {
        all_outbound = {
          description = "Permit All traffic outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https_inbound = {
          description = "Permit HTTPS from lambda subnets"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["10.100.0.0/25", "10.100.64.0/25"]
        }
      }
    }
  }
}

module "subnet_set_lambda" {
  source = "../../modules/subnet_set"

  name                = "${var.prefix_name_tag}lambda"
  vpc_id              = module.vpc.id
  has_secondary_cidrs = module.vpc.has_secondary_cidrs
  global_tags         = var.global_tags
  cidrs = {
    "10.100.0.0/25"  = { az = "us-east-1a" }
    "10.100.64.0/25" = { az = "us-east-1b" }
  }
}

#
# PrivateLink to the Amazon EC2 API.
#
# In other words, network interfaces that can, for example, understand https API call to AWS to reboot an EC2 instance.
#
module "ec2api_endpoint" {
  source = "../../modules/vpc_endpoint"

  name                = "ec2api-endpoint"
  simple_service_name = "ec2"
  type                = "Interface"
  vpc_id              = module.vpc.id
  security_group_ids  = [module.vpc.security_group_ids["vpc_endpoint"]]
  subnets             = module.subnet_set_lambda.subnets
  private_dns_enabled = false
  tags                = merge(var.global_tags, { Description = "PrivateLink to the Amazon EC2 API." })
}

#
# PrivateLink to the Amazon API Gateway.
#
module "apigw_endpoint" {
  source = "../../modules/vpc_endpoint"

  name                = "apigw-endpoint"
  simple_service_name = "execute-api"
  type                = "Interface"
  vpc_id              = module.vpc.id
  security_group_ids  = [module.vpc.security_group_ids["vpc_endpoint"]]
  subnets             = module.subnet_set_lambda.subnets
}

#
# Routing to S3 which does not traverse the public Internet.
#
module "s3_endpoint" {
  source = "../../modules/vpc_endpoint"

  name                = "s3-endpoint"
  simple_service_name = "s3"
  type                = "Gateway"
  vpc_id              = module.vpc.id
  # The "Gateway" endpoint accepts route tables instead of subnets.
  # route_table_ids = module.subnet_set_lambda.unique_route_table_ids
  route_table_ids = {}
}

module "s3_endpoint_read" {
  source = "../../modules/vpc_endpoint"

  create              = false
  name                = "s3-endpoint"
  simple_service_name = "s3"
  type                = "Gateway"
  vpc_id              = module.vpc.id
  route_table_ids     = module.subnet_set_lambda.unique_route_table_ids

  depends_on = [
    module.s3_endpoint
  ]
}
