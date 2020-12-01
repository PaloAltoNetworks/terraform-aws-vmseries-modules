

### Inbound / Outbound ###
module "north-south_vpc" {
  source           = "../../../../modules/vpc"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.north-south_vpc
  vpc_route_tables = var.north-south_vpc_route_tables
  subnets          = var.north-south_vpc_subnets
  nat_gateways     = var.north-south_nat_gateways
  vpc_endpoints    = var.north-south_vpc_endpoints
  security_groups  = var.north-south_vpc_security_groups
}

module "north-south_vmseries" {
  source               = "../../../../modules/vmseries"
  region               = var.region
  prefix_name_tag      = var.prefix_name_tag
  ssh_key_name         = var.ssh_key_name
  fw_license_type      = var.fw_license_type
  fw_version           = var.fw_version
  fw_instance_type     = var.fw_instance_type
  tags                 = var.global_tags
  firewalls            = var.north-south_firewalls
  interfaces           = var.north-south_interfaces
  addtional_interfaces = var.north-south_addtional_interfaces
  subnets_map          = module.north-south_vpc.subnet_ids
  security_groups_map  = module.north-south_vpc.security_group_ids
  # buckets_map          = local.buckets_map
  # prefix_bootstrap     = "pan-bootstrap-ns"
}

module "north-south_vpc_routes" {
  source            = "../../../../modules/vpc_routes"
  region            = var.region
  global_tags       = var.global_tags
  prefix_name_tag   = var.prefix_name_tag
  vpc_routes        = var.north-south_vpc_routes
  vpc_route_tables  = module.north-south_vpc.route_table_ids
  internet_gateways = module.north-south_vpc.internet_gateway_id
  nat_gateways      = module.north-south_vpc.nat_gateway_ids
  vpc_endpoints     = module.gwlb.endpoint_ids
}

# We need to generate a list of subnet IDs
locals {
  trusted_subnet_ids = [
    for s in var.gwlb_subnets :
    module.north-south_vpc.subnet_ids[s]
  ]
}

module "gwlb" {
  source                          = "../../../../modules/gwlb"
  region                          = var.region
  global_tags                     = var.global_tags
  prefix_name_tag                 = var.prefix_name_tag
  vpc_id                          = module.north-south_vpc.vpc_id.vpc_id
  gateway_load_balancers          = var.gateway_load_balancers
  gateway_load_balancer_endpoints = var.gateway_load_balancer_endpoints
  name                            = "zzz"
  firewalls                       = module.north-south_vmseries.firewalls
  subnet_ids                      = local.trusted_subnet_ids
  subnets_map                     = module.north-south_vpc.subnet_ids
}


output "tg" { value = module.gwlb.target_group }
output "firewalls" { value = module.north-south_vmseries.firewalls }