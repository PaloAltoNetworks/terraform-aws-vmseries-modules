data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = var.base_infra_state_bucket
    key     = var.base_infra_state_key
    region  = var.base_infra_state_region
    profile = var.shared_cred_profile
  }
}

data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket  = var.base_infra_state_bucket
    key     = var.panorama_bootstrap_state_key
    region  = var.base_infra_state_region
    profile = var.shared_cred_profile
  }
}

module "pan_fw" {
  source               = "../../modules/vdss_pan_fws"
  buckets_map          = data.terraform_remote_state.bootstrap.outputs.bootstrap_s3_buckets
  subnets_map          = data.terraform_remote_state.vpc.outputs.subnets
  security_groups_map  = data.terraform_remote_state.vpc.outputs.security_groups
  route_tables_map     = merge(data.terraform_remote_state.vpc.outputs.route_tables, data.terraform_remote_state.vpc.outputs.gateway_route_tables)
  prefix_name_tag      = var.prefix_name_tag
  interfaces           = var.interfaces
  addtional_interfaces = var.addtional_interfaces
  region               = var.region
  tags                 = var.tags
  ssh_key_name         = var.ssh_key_name
  firewalls            = var.firewalls
  fw_license_type      = var.fw_license_type
  fw_version           = var.fw_version
  fw_instance_type     = var.fw_instance_type
  rts_to_fw_eni        = var.rts_to_fw_eni
}
