module "vpc_all_options" {
  source           = "../../"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpc
  vpc_route_tables = var.vpc_route_tables
  subnets          = var.subnets
  nat_gateways     = var.nat_gateways
  vpn_gateways     = var.vpn_gateways
  vpc_endpoints    = var.vpc_endpoints
  security_groups  = var.security_groups
}

