module "vmseries" {
  source              = "../../modules/vmseries"
  region              = var.region
  tags                = var.tags
  ssh_key_name        = var.ssh_key_name
  interfaces          = var.interfaces
  firewalls           = var.firewalls
  prefix_name_tag     = var.prefix_name_tag
  security_groups_map = var.security_groups_map
  subnets_map         = var.subnets_map
}
