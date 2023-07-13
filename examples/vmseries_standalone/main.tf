### VPCS ###

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                    = "${var.name_prefix}${each.value.name}"
  cidr_block              = each.value.cidr
  nacls                   = each.value.nacls
  security_groups         = each.value.security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

### SUBNETS ###

module "subnet_sets" {
  for_each = toset(flatten([for _, v in { for vk, vv in var.vpcs : vk => distinct([for sk, sv in vv.subnets : "${vk}-${sv.set}"]) } : v]))
  source   = "../../modules/subnet_set"

  name                = split("-", each.key)[1]
  vpc_id              = module.vpc[split("-", each.key)[0]].id
  has_secondary_cidrs = module.vpc[split("-", each.key)[0]].has_secondary_cidrs
  nacl_associations = {
    for i in flatten([
      for vk, vv in var.vpcs : [
        for sk, sv in vv.subnets :
        {
          az : sv.az,
          nacl_id : lookup(module.vpc[split("-", each.key)[0]].nacl_ids, sv.nacl, null)
        } if sv.nacl != null && each.key == "${vk}-${sv.set}"
    ]]) : i.az => i.nacl_id
  }
  cidrs = {
    for i in flatten([
      for vk, vv in var.vpcs : [
        for sk, sv in vv.subnets :
        {
          cidr : sk,
          subnet : sv
        } if each.key == "${vk}-${sv.set}"
    ]]) : i.cidr => i.subnet
  }
}

### ROUTES ###

locals {
  vpc_routes = flatten(concat([
    for vk, vv in var.vpcs : [
      for rk, rv in vv.routes : {
        subnet_key = rv.vpc_subnet
        to_cidr    = rv.to_cidr
        next_hop_set = (
          rv.next_hop_type == "internet_gateway" ? module.vpc[rv.next_hop_key].igw_as_next_hop_set : null
        )
      }
    ]
  ]))
}

module "vpc_routes" {
  for_each = { for route in local.vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

### IAM ROLES AND POLICIES ###

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
        "arn:aws:logs:*:*:*:*:*",
        "arn:aws:logs:*:*:*",
        "arn:aws:cloudwatch:*:*:*"
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

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])

  bootstrap_options = { for i, j in var.vmseries : i => [
    for k, v in j.bootstrap_options : "${k}=${v}"
  ] }
}

module "vmseries" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  source   = "../../modules/vmseries"

  name             = "${var.name_prefix}${each.key}"
  vmseries_version = each.value.common.panos_version

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      private_ips        = [v.private_ip]
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = module.subnet_sets[v.vpc_subnet].subnets[each.value.az].id
      create_public_ip   = try(v.create_public_ip, false)
    }
  }

  bootstrap_options = join(";", compact(concat(local.bootstrap_options[each.value.group], ["hostname=${var.name_prefix}${each.key}"])))

  iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}
