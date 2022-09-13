module "bootstrap" {
  source      = "../../modules/bootstrap"
  prefix      = var.name_prefix
  global_tags = var.global_tags
}

module "vmseries" {
  for_each = var.vmseries
  source   = "../../modules/vmseries"

  name             = "${var.name_prefix}${each.key}"
  vmseries_version = var.vmseries_version
  interfaces = {
    data1 = {
      device_index       = 0
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_data"]]
      source_dest_check  = false
      subnet_id          = module.security_subnet_sets["data1"].subnets[each.value.az].id
      create_public_ip   = false
    },
    mgmt = {
      device_index       = 1
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_mgmt"]]
      source_dest_check  = true
      subnet_id          = module.security_subnet_sets["mgmt"].subnets[each.value.az].id
      create_public_ip   = true
    }
  }

  bootstrap_options = join(";", compact(concat(
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap.bucket_name}"],
    [for k, v in var.vmseries_common.bootstrap_options : "${k}=${v}"],
  )))

  iam_instance_profile = module.bootstrap.instance_profile_name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}
