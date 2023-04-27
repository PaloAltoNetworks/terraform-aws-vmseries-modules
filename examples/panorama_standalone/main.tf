### VPCS ###

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                    = "${var.name_prefix}${each.value.name}"
  cidr_block              = each.value.cidr
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
  nacl_associations   = {}
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
          # Please note, that in this example only internet_gateway is allowed, because no NAT Gateway, TGW or GWLB endpoints are created in main.tf
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

resource "aws_iam_role" "this" {
  for_each           = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama if panorama.common.iam.create_role }
  name               = "${var.name_prefix}${each.value.common.iam.role_name}"
  description        = "Allow read-only access to AWS resources."
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags               = var.global_tags
}

resource "aws_iam_role_policy" "this" {
  for_each = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama if panorama.common.iam.create_role }
  role     = aws_iam_role.this[each.key].id
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        }
    ]
}

EOF
}

resource "aws_iam_instance_profile" "this" {
  for_each = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama }
  name     = "${var.name_prefix}panorama_instance_profile"
  role     = each.value.common.iam.create_role ? aws_iam_role.this[each.key].name : each.value.common.iam.role_name
}

### KMS ###

data "aws_ebs_default_kms_key" "this" {
}

data "aws_kms_alias" "this" {
  for_each = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama if anytrue([for ebs in panorama.common.ebs.volumes : ebs.ebs_encrypted]) }

  name = each.value.common.ebs.kms_key_alias != null ? "alias/${each.value.common.ebs.kms_key_alias}" : data.aws_ebs_default_kms_key.this.key_arn
}

### PANORAMA INSTANCES

locals {
  panorama_instances = flatten([for kv, vv in var.panorama : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "panorama" {
  for_each = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama }
  source   = "../../modules/panorama"

  name                   = "${var.name_prefix}${each.key}"
  availability_zone      = each.value.az
  create_public_ip       = each.value.common.network.create_public_ip
  ebs_volumes            = each.value.common.ebs.volumes
  panorama_version       = each.value.common.panos_version
  ssh_key_name           = var.ssh_key_name
  ebs_kms_key_alias      = try(data.aws_kms_alias.this[each.key].target_key_arn, null)
  subnet_id              = module.subnet_sets[each.value.common.network.vpc_subnet].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.common.network.vpc].security_group_ids[each.value.common.network.security_group]]
  panorama_iam_role      = aws_iam_instance_profile.this[each.key].name

  global_tags = var.global_tags

  depends_on = [
    aws_iam_instance_profile.this
  ]
}
