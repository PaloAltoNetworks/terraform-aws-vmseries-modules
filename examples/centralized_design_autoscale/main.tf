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
          rv.next_hop_type == "internet_gateway" ? module.vpc[rv.next_hop_key].igw_as_next_hop_set : (
            rv.next_hop_type == "nat_gateway" ? module.natgw_set[rv.next_hop_key].next_hop_set : (
              rv.next_hop_type == "transit_gateway_attachment" ? module.transit_gateway_attachment[rv.next_hop_key].next_hop_set : (
                rv.next_hop_type == "gwlbe_endpoint" ? module.gwlbe_endpoint[rv.next_hop_key].next_hop_set : null
              )
            )
          )
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

### NATGW ###

module "natgw_set" {
  source = "../../modules/nat_gateway_set"

  for_each = var.natgws

  subnets = module.subnet_sets[each.value.vpc_subnet].subnets
}

### TGW ###

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  create       = var.tgw.create
  id           = var.tgw.id
  name         = "${var.name_prefix}${var.tgw.name}"
  asn          = var.tgw.asn
  route_tables = var.tgw.route_tables
}

### TGW ATTACHMENTS ###

module "transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  for_each = var.tgw.attachments

  name                        = "${var.name_prefix}${each.value.name}"
  vpc_id                      = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets                     = module.subnet_sets[each.value.vpc_subnet].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables[each.value.route_table]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables[each.value.propagate_routes_to].id
  }
}

resource "aws_ec2_transit_gateway_route" "from_spokes_to_security" {
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_spoke_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_attachment["security"].attachment.id
  destination_cidr_block         = "0.0.0.0/0"
  blackhole                      = false
}

resource "aws_ec2_transit_gateway_route" "from_security_to_panorama" {
  count                          = var.panorama_attachment.transit_gateway_attachment_id != null ? 1 : 0
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_security_vpc"].id
  transit_gateway_attachment_id  = var.panorama_attachment.transit_gateway_attachment_id
  destination_cidr_block         = var.panorama_attachment.vpc_cidr
  blackhole                      = false
}

### GWLB ###

module "gwlb" {
  source = "../../modules/gwlb"

  for_each = var.gwlbs

  name    = "${var.name_prefix}${each.value.name}"
  vpc_id  = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets = module.subnet_sets[each.value.vpc_subnet].subnets
}

### GWLB ENDPOINTS ###

module "gwlbe_endpoint" {
  source = "../../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = "${var.name_prefix}${each.value.name}"
  gwlb_service_name = module.gwlb[each.value.gwlb].endpoint_service.service_name
  vpc_id            = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets           = module.subnet_sets[each.value.vpc_subnet].subnets

  act_as_next_hop_for = each.value.act_as_next_hop ? {
    "from-igw-to-lb" = {
      route_table_id = module.vpc[each.value.vpc].internet_gateway_route_table.id
      to_subnets     = module.subnet_sets[each.value.to_vpc_subnets].subnets
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table,
    # and AWS allows their destinations to only be:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table
  } : {}
}

### SPOKE VM INSTANCES ####

data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.25*-linux-debian-11-x86_64-hvm-ebs-nami"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  owners = ["979382823631"] # bitnami = 979382823631
}

data "aws_ebs_default_kms_key" "current" {
}

data "aws_kms_alias" "current_arn" {
  name = data.aws_ebs_default_kms_key.current.key_arn
}

resource "aws_iam_role" "spoke_vm_ec2_iam_role" {
  name               = "${var.name_prefix}spoke_vm"
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

resource "aws_iam_instance_profile" "spoke_vm_iam_instance_profile" {

  name = "${var.name_prefix}spoke_vm_instance_profile"
  role = aws_iam_role.spoke_vm_ec2_iam_role.name
}

resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.subnet_sets[each.value.vpc_subnet].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
  iam_instance_profile   = aws_iam_instance_profile.spoke_vm_iam_instance_profile.name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_alias.current_arn.target_key_arn
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "app_lb" {
  source = "../../modules/nlb"

  for_each = var.spoke_lbs

  name        = "${var.name_prefix}${each.key}"
  internal_lb = true
  subnets     = { for k, v in module.subnet_sets[each.value.vpc_subnet].subnets : k => { id = v.id } }
  vpc_id      = module.subnet_sets[each.value.vpc_subnet].vpc_id

  balance_rules = {
    "SSH-traffic" = {
      protocol    = "TCP"
      port        = "22"
      target_type = "instance"
      stickiness  = true
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
    "HTTP-traffic" = {
      protocol    = "TCP"
      port        = "80"
      target_type = "instance"
      stickiness  = false
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
    "HTTPS-traffic" = {
      protocol    = "TCP"
      port        = "443"
      target_type = "instance"
      stickiness  = false
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
  }

  tags = var.global_tags
}

### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###

locals {
  subinterface_gwlb_endpoint_eastwest = { for i, j in var.vmseries_asgs : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.eastwest : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_outbound = { for i, j in var.vmseries_asgs : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.outbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_inbound = { for i, j in var.vmseries_asgs : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.inbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => format("%s,%s,%s,%s", j.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest[i], local.subinterface_gwlb_endpoint_outbound[i], local.subinterface_gwlb_endpoint_inbound[i]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"
  ] }
}

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

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
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": [
        "arn:${data.aws_partition.this.partition}:cloudwatch:${var.region}:${data.aws_caller_identity.this.account_id}:alarm:*"
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

### AUTOSCALING GROUP WITH VM-Series INSTANCES ###

module "vm_series_asg" {
  source = "../../modules/asg"

  for_each = var.vmseries_asgs

  ssh_key_name                  = var.ssh_key_name
  region                        = var.region
  name_prefix                   = var.name_prefix
  global_tags                   = var.global_tags
  vmseries_version              = each.value.panos_version
  max_size                      = each.value.asg.max_size
  min_size                      = each.value.asg.min_size
  desired_capacity              = each.value.asg.desired_cap
  vmseries_iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  subnet_ids                    = [for i, j in var.vpcs[each.value.vpc].subnets : module.subnet_sets[format("%s-lambda", each.value.vpc)].subnets[j.az].id if j.set == "lambda"]
  security_group_ids            = contains(keys(module.vpc[each.value.vpc].security_group_ids), "lambda") ? [module.vpc[each.value.vpc].security_group_ids["lambda"]] : []
  interfaces = {
    for k, v in each.value.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.vpc[each.value.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = { for z, c in v.subnet : c => module.subnet_sets[format("%s-%s", each.value.vpc, k)].subnets[c].id }
      create_public_ip   = try(v.create_public_ip, false)
    }
  }
  ebs_kms_id       = each.value.ebs_kms_id
  target_group_arn = module.gwlb[each.value.gwlb].target_group.arn
  ip_target_groups = concat(
    [for k, v in module.public_alb[each.key].target_group : { arn : v.arn, port : v.port }],
    [for k, v in module.public_nlb[each.key].target_group : { arn : v.arn, port : v.port }],
  )
  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.key])))

  scaling_plan_enabled         = each.value.scaling_plan.enabled
  scaling_metric_name          = each.value.scaling_plan.metric_name
  scaling_target_value         = each.value.scaling_plan.target_value
  scaling_statistic            = each.value.scaling_plan.statistic
  scaling_cloudwatch_namespace = each.value.scaling_plan.cloudwatch_namespace
  scaling_tags                 = merge(each.value.scaling_plan.tags, { prefix : var.name_prefix })
}

### Public ALB and NLB used in centralized model ###

module "public_alb" {
  for_each = { for k, v in var.vmseries_asgs : k => v }
  source   = "../../modules/alb"

  lb_name         = "${var.name_prefix}${each.value.application_lb.name}"
  subnets         = { for k, v in module.subnet_sets["security_vpc-alb"].subnets : k => { id = v.id } }
  vpc_id          = module.vpc["security_vpc"].id
  security_groups = [module.vpc["security_vpc"].security_group_ids["application_load_balancer"]]
  rules           = each.value.application_lb.rules
  targets         = {}

  tags = var.global_tags
}

module "public_nlb" {
  for_each = { for k, v in var.vmseries_asgs : k => v }
  source   = "../../modules/nlb"

  name        = "${var.name_prefix}${each.value.network_lb.name}"
  internal_lb = false
  subnets     = { for k, v in module.subnet_sets["security_vpc-nlb"].subnets : k => { id = v.id } }
  vpc_id      = module.vpc["security_vpc"].id

  balance_rules = { for k, v in each.value.network_lb.rules : k => {
    protocol    = v.protocol
    port        = v.port
    target_type = v.target_type
    stickiness  = v.stickiness
    targets     = {}
  } }

  tags = var.global_tags
}
