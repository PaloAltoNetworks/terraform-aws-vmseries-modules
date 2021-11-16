### VPC
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



### VMSERIES
module "vmseries" {
  source              = "../.."
  region              = var.region
  prefix_name_tag     = var.prefix_name_tag
  ssh_key_name        = var.ssh_key_name
  fw_license_type     = var.fw_license_type
  fw_version          = var.fw_version
  fw_instance_type    = var.fw_instance_type
  tags                = var.global_tags
  firewalls           = var.firewalls
  interfaces          = var.interfaces
  subnets_map         = module.vpc.subnet_ids
  security_groups_map = module.vpc.security_group_ids
  # buckets_map         = local.buckets_map
}
