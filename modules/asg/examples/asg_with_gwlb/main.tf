data "archive_file" "this" {
  type        = "zip"
  source_file = "../../../asg/lambda.py"
  output_path = "lambda_payload.zip"
}

module "vpc" {
  source           = "../../../vpc"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpcs
  vpc_route_tables = var.route_tables
  subnets          = var.vpc_subnets
  security_groups  = var.security_groups
}

module "asg" {
  source             = "../../../asg"
  ssh_key_name       = var.ssh_key_name
  name_prefix        = var.prefix_name_tag
  bootstrap_options  = var.bootstrap_options
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = module.vpc.security_group_ids
  interfaces         = var.interfaces
  subnets            = var.nic0_subnets
  global_tags        = var.global_tags
  max_size           = 0
  min_size           = 0
  desired_capacity   = 0
}

# We need to generate a list of subnet IDs
locals {
  trusted_subnet_ids = [
    for s in var.gateway_load_balancer_subnets :
    module.vpc.subnet_ids[s]
  ]
}

module "gwlb" {
  source                          = "../../../gwlb"
  name                            = "zzz"
  region                          = var.region
  global_tags                     = var.global_tags
  prefix_name_tag                 = var.prefix_name_tag
  vpc_id                          = module.vpc.vpc_id.vpc_id
  gateway_load_balancers          = var.gateway_load_balancers
  gateway_load_balancer_endpoints = var.gateway_load_balancer_endpoints
  subnet_ids                      = local.trusted_subnet_ids
  subnets_map                     = module.vpc.subnet_ids
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = module.asg.asg.id
  alb_target_group_arn   = module.gwlb.target_group.security-gwlb.arn
}
