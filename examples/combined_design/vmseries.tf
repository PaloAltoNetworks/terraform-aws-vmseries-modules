/*### IAM ROLES AND POLICIES ###

resource "aws_iam_role" "vm_series_ec2_iam_role" {
  name               = "${var.name_prefix}vmseries"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "vm_series_ec2_iam_policy" {
  role   = aws_iam_role.vm_series_ec2_iam_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:GetMetricData",
        "cloudwatch:PutMetricData",
        "cloudwatch:ListMetrics",
        "cloudwatch:DescribeAlarms",
        "logs:CreateLogGroup"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}

EOF
}

resource "aws_iam_instance_profile" "vm_series_iam_instance_profile" {

  name = "${var.name_prefix}vmseries_instance_profile"
  role = aws_iam_role.vm_series_ec2_iam_role.name
}

### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###

locals {
  subinterface_gwlb_endpoint_eastwest = { for i, j in var.vmseries_common : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.eastwest : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_outbound = { for i, j in var.vmseries_common : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.outbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_inbound = { for i, j in var.vmseries_common : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.inbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries_common : i => format("%s,%s,%s,%s", j.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest[i], local.subinterface_gwlb_endpoint_outbound[i], local.subinterface_gwlb_endpoint_inbound[i]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries_common : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"
  ] }
}

module "vmseries" {
  for_each = var.vmseries
  source = "../../modules/vmseries"

  name = each.key
  vmseries_version = var.vmseries_common.main.panos_version
  interfaces = {
    data = {
      device_index = 0
      security_group_ids = [module.vpc["security_vpc"].security_group_ids["vmseries_private"]]
      source_dest_check = false
      subnet_id = module.subnet_sets["security_vpc-data"].subnets[each.value.az].id
    },
    mgmt = {
      device_index = 1
      security_group_ids = [module.vpc["security_vpc"].security_group_ids["vmseries_mgmt"]]
      source_dest_check = true
      subnet_id = module.subnet_sets["security_vpc-mgmt"].subnets[each.value.az].id
    }
  }

  bootstrap_options = join(";", compact(concat(
    [for k, v in var.vmseries_common.main.bootstrap_options : "${k}=${v}"],
    #local.bootstrap_options_with_endpoints_mapping["main"]
    )))
  ssh_key_name = var.ssh_key_name
  tags = var.global_tags
  iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
}*/