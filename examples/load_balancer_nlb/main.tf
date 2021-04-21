module vpc {
  source = "../../modules/vpc/"

  region           = var.region
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpc
  vpc_route_tables = var.route_tables
  subnets          = var.subnets
  security_groups  = var.security_groups
}

module single_vpc_routes {
  source = "../../modules/vpc_routes"

  region            = var.region
  global_tags       = var.global_tags
  prefix_name_tag   = var.prefix_name_tag
  vpc_routes        = var.routes
  vpc_route_tables  = module.vpc.route_table_ids
  internet_gateways = module.vpc.internet_gateway_id
}

module "aws_elbs" {
  source = "../../modules/load_balancer"

  vpc_id              = module.vpc.vpc_id.vpc_id
  global_tags         = var.global_tags
  elb_subnet_ids      = [module.vpc.subnet_ids["private-1a"], module.vpc.subnet_ids["private-1b"]]
  target_instance_ids = [aws_instance.web1.id, aws_instance.web2.id]
  # target_instance_ids = []
  nlbs = var.nlbs
  albs = {}
}

output "test" {
  value = [module.vpc.subnet_ids["private-1a"]]
}