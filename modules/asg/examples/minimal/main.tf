module "vpc" {
  source           = "../../../vpc"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpcs
  vpc_route_tables = var.route_tables
  subnets          = var.vpc_subnets
  # nat_gateways     = var.nat_gateways
  # vpc_endpoints    = var.vpc_endpoints
  security_groups = var.security_groups
}

module "asg" {
  source            = "../../../asg"
  ssh_key_name      = var.ssh_key_name
  name_prefix       = var.prefix_name_tag
  bootstrap_options = var.bootstrap_options
  subnet_ids        = module.vpc.subnet_ids
  interfaces        = var.interfaces
  # global_tags      = var.global_tags
  # vpc              = var.vpcs
  # vpc_route_tables = var.route_tables
  # subnets          = var.vpc_subnets
  # # nat_gateways     = var.nat_gateways
  # # vpc_endpoints    = var.vpc_endpoints
  # security_groups = var.security_groups
}
