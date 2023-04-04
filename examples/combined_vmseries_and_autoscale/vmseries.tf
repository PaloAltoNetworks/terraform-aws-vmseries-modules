### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###

locals {
  subinterface_gwlb_endpoint_eastwest = join(",", compact(concat([
    for k, v in module.gwlbe_eastwest.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.eastwest)
  ])))
  subinterface_gwlb_endpoint_outbound = join(",", compact(concat([
    for k, v in module.gwlbe_outbound.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.outbound)
  ])))
  subinterface_gwlb_endpoint_inbound1 = join(",", compact(concat([
    for k, v in module.app1_gwlbe_inbound.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.inbound1)
  ])))
  subinterface_gwlb_endpoint_inbound2 = join(",", compact(concat([
    for k, v in module.app2_gwlbe_inbound.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.vmseries_common.subinterfaces.inbound2)
  ])))
  plugin_op_commands_with_endpoints_mapping = format("%s,%s,%s,%s,%s", var.vmseries_common.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest, local.subinterface_gwlb_endpoint_outbound, local.subinterface_gwlb_endpoint_inbound1, local.subinterface_gwlb_endpoint_inbound2)
  bootstrap_options_with_endpoints_mapping = [
    for k, v in var.vmseries_common.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping}"
  ]
}

### AUTOSCALING GROUP WITH VM-Series INSTANCES ###

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

module "vm_series_asg" {
  source = "../../modules/asg"

  ssh_key_name                  = var.ssh_key_name
  region                        = var.region
  name_prefix                   = var.name_prefix
  global_tags                   = var.global_tags
  vmseries_version              = var.vmseries_version
  max_size                      = var.asg_max_size
  min_size                      = var.asg_min_size
  desired_capacity              = var.asg_desired_cap
  vmseries_iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  subnet_ids                    = [for k, v in var.security_vpc_subnets : module.security_subnet_sets["lambda"].subnets[v.az].id if v.set == "lambda"]
  security_group_ids            = [module.security_vpc.security_group_ids["lambda"]]
  interfaces = {
    for k, v in var.vmseries_interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.security_vpc.security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = { for z, c in v.subnet : c => module.security_subnet_sets[k].subnets[c].id }
      create_public_ip   = try(v.create_public_ip, false)
    }
  }
  ebs_kms_id        = var.ebs_kms_id
  target_group_arn  = module.security_gwlb.target_group.arn
  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping)))

  scaling_plan_enabled         = var.scaling_plan_enabled
  scaling_metric_name          = var.scaling_metric_name
  scaling_tags                 = var.scaling_tags
  scaling_target_value         = var.scaling_target_value
  scaling_cloudwatch_namespace = var.scaling_cloudwatch_namespace
}
