module "bootstrap" {
  source             = "../../modules/bootstrap"
  prefix             = var.name_prefix
  global_tags        = var.global_tags
  plugin-op-commands = local.plugin_op_commands_with_endpoints_mapping
}

locals {
  subinterface_gwlb_endpoint_eastwest = join(",", compact(concat([
    for k, v in module.gwlbe_eastwest.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.eastwest)
  ])))
  subinterface_gwlb_endpoint_outbound = join(",", compact(concat([
    for k, v in module.gwlbe_outbound.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.outbound)
  ])))
  subinterface_gwlb_endpoint_inbound = join(",", compact(concat([
    for k, v in module.app1_gwlbe_inbound.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.inbound)
  ])))
  plugin_op_commands_with_endpoints_mapping = format("%s,%s,%s,%s", var.vmseries_common.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest, local.subinterface_gwlb_endpoint_outbound, local.subinterface_gwlb_endpoint_inbound)
  bootstrap_options_with_endpoints_mapping = [
    for k, v in var.vmseries_common.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping}"
  ]
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
    ### first option - use init-cfg.txt created from template and stored in S3 bucket
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap.bucket_name}"],
    [for k, v in var.vmseries_common.bootstrap_options : "${k}=${v}"],

    ### second option - add generated bootstrap settings directly to VM-Series in user data
    # local.bootstrap_options_with_endpoints_mapping,
  )))

  iam_instance_profile = module.bootstrap.instance_profile_name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}
