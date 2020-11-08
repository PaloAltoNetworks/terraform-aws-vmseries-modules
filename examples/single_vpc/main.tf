module single_vpc {
  source           = "../../modules/vpc/"
  region           = var.region
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

############################################################
# Call Route module
############################################################

module single_vpc_routes {
  source            = "../../modules/vpc_routes"
  region            = var.region
  global_tags       = var.global_tags
  prefix_name_tag   = var.prefix_name_tag
  vpc_routes        = var.vpc_routes
  vpc_route_tables  = module.single_vpc.route_table_ids
  internet_gateways = module.single_vpc.internet_gateway_id
}

############################################################
# Call VM-Series
############################################################


module "vmseries" {
  source               = "../../modules/vmseries"
  region               = var.region
  subnets_map          = module.single_vpc.subnet_ids
  security_groups_map  = module.single_vpc.security_group_ids
  prefix_name_tag      = var.prefix_name_tag
  interfaces           = var.interfaces
  addtional_interfaces = var.addtional_interfaces
  tags                 = var.global_tags
  ssh_key_name         = var.ssh_key_name
  firewalls            = var.firewalls
  fw_license_type      = var.fw_license_type
  fw_version           = var.fw_version
  fw_instance_type     = var.fw_instance_type
}