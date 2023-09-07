locals {
  subnets = toset(flatten([for _, v in { for vk, vv in var.vpcs : vk => distinct([for sk, sv in vv.subnets : {
    name : split("-", "${vk}-${sv.set}")[1]
    az : sv.az # substr(sv.az, -1, -1)
  }]) } : v]))
  nat_gateways = flatten([for m, n in var.natgws : [for k, v in n.nat_gateway_names : {
    key : "${m}-${k}"
    name : v
  }]])
  nlb_tg = flatten([for k, v in var.spoke_nlbs : [for i, r in v.rules : {
    key   = "${k}-${i}",
    value = "${k}-${r.port}"
  }]])
  alb_tg = flatten([for k, v in var.spoke_albs : [for i, r in v.rules : {
    key   = "${k}-${i}",
    value = "${k}-${r.port}"
  }]])
}

module "names" {
  source = "../../modules/names_generator"

  region         = var.region
  name_delimiter = var.name_templates.name_delimiter
  name_template  = var.name_templates.name_template
  abbreviations  = var.name_templates.abbreviations
  names = {
    vpc = {
      template = lookup(var.name_templates.assign_template, "vpc", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.vpcs : k => v.name }
    }
    internet_gateway = {
      template = lookup(var.name_templates.assign_template, "internet_gateway", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.vpcs : k => v.name }
    }
    vpn_gateway = {
      template = lookup(var.name_templates.assign_template, "vpn_gateway", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.vpcs : k => v.name }
    }
    subnet = {
      template = lookup(var.name_templates.assign_template, "subnet", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for _, v in local.subnets : "${v.name}${v.az}" => "${v.name}${v.az}" }
    }
    route_table = {
      template = lookup(var.name_templates.assign_template, "subnet", lookup(var.name_templates.assign_template, "default", "default")),
      values = merge(
        { for k, v in var.vpcs : k => "igw_${v.name}" },
        { for _, v in local.subnets : "${v.name}${v.az}" => "${v.name}${v.az}" }
      )
    }
    nat_gateway = {
      template = lookup(var.name_templates.assign_template, "nat_gateway", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for _, v in local.nat_gateways : v.key => v.name }
    }
    transit_gateway = {
      template = lookup(var.name_templates.assign_template, "transit_gateway", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { "tgw" : var.tgw.name }
    }
    transit_gateway_attachment = {
      template = lookup(var.name_templates.assign_template, "transit_gateway_attachment", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.tgw.attachments : k => v.name }
    }
    gateway_loadbalancer = {
      template = lookup(var.name_templates.assign_template, "gateway_loadbalancer", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.gwlbs : k => v.name }
    }
    gateway_loadbalancer_target_group = {
      template = lookup(var.name_templates.assign_template, "gateway_loadbalancer_target_group", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.gwlbs : k => v.name }
    }
    gateway_loadbalancer_endpoint = {
      template = lookup(var.name_templates.assign_template, "gateway_loadbalancer_endpoint", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.gwlb_endpoints : k => v.name }
    }
    application_loadbalancer = {
      template = lookup(var.name_templates.assign_template, "application_loadbalancer", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.spoke_albs : k => k }
    }
    application_loadbalancer_target_group = {
      template = lookup(var.name_templates.assign_template, "application_loadbalancer_target_group", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for _, v in local.alb_tg : v.key => v.value }
    }
    network_loadbalancer = {
      template = lookup(var.name_templates.assign_template, "network_loadbalancer", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.spoke_nlbs : k => k }
    }
    network_loadbalancer_target_group = {
      template = lookup(var.name_templates.assign_template, "network_loadbalancer_target_group", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for _, v in local.nlb_tg : v.key => v.value }
    }
    vm = {
      template = lookup(var.name_templates.assign_template, "vm", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.spoke_vms : k => k }
    }
    vmseries = {
      template = lookup(var.name_templates.assign_template, "vmseries", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => "${vmseries.group}-${vmseries.instance}" }
    }
    iam_role = {
      template = lookup(var.name_templates.assign_template, "iam_role", lookup(var.name_templates.assign_template, "default", "default")),
      values = {
        security : "vmseries"
        spoke : "spokevm"
      }
    }
    iam_instance_profile = {
      template = lookup(var.name_templates.assign_template, "iam_instance_profile", lookup(var.name_templates.assign_template, "default", "default")),
      values = {
        security : "vmseries"
        spoke : "spokevm"
      }
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                         = module.names.vpc_name[each.key]
  cidr_block                   = each.value.cidr
  nacls                        = each.value.nacls
  security_groups              = each.value.security_groups
  create_internet_gateway      = true
  name_internet_gateway        = module.names.internet_gateway_name[each.key]
  route_table_internet_gateway = module.names.route_table_name[each.key]
  enable_dns_hostnames         = true
  enable_dns_support           = true
  instance_tenancy             = "default"
}

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
          subnet : merge(sv, {
            name             = module.names.subnet_name["${split("-", each.key)[1]}${sv.az}"]
            route_table_name = module.names.route_table_name["${split("-", each.key)[1]}${sv.az}"]
          })
        } if each.key == "${vk}-${sv.set}"
    ]]) : i.cidr => i.subnet
  }
}

### NATGW ###

module "natgw_set" {
  source = "../../modules/nat_gateway_set"

  for_each = var.natgws

  subnets           = module.subnet_sets[each.value.vpc_subnet].subnets
  nat_gateway_names = { for k, v in each.value.nat_gateway_names : k => module.names.nat_gateway_name["${each.key}-${k}"] }
}

### TGW ###
module "transit_gateway" {
  source = "../../modules/transit_gateway"

  create       = var.tgw.create
  id           = var.tgw.id
  name         = module.names.transit_gateway_name["tgw"]
  asn          = var.tgw.asn
  route_tables = var.tgw.route_tables
}

### TGW ATTACHMENTS ###

module "transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  for_each = var.tgw.attachments

  name                        = module.names.transit_gateway_attachment_name[each.key]
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

  name    = module.names.gateway_loadbalancer_name[each.key]
  tg_name = module.names.gateway_loadbalancer_target_group_name[each.key]
  vpc_id  = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets = module.subnet_sets[each.value.vpc_subnet].subnets
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => {
    gwlb = vmseries.common.gwlb
    id   = module.vmseries["${vmseries.group}-${vmseries.instance}"].instance.id
  } }

  target_group_arn = module.gwlb[each.value.gwlb].target_group.arn
  target_id        = each.value.id
}

### GWLB ENDPOINTS ###

module "gwlbe_endpoint" {
  source = "../../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = module.names.gateway_loadbalancer_endpoint_name[each.key]
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
  #vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "vpc_routes" {
  for_each = { for route in local.vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###

locals {
  subinterface_gwlb_endpoint_eastwest = { for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.eastwest : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_outbound = { for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.outbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_inbound = { for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.inbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries : i => format("%s,%s,%s,%s", j.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest[i], local.subinterface_gwlb_endpoint_outbound[i], local.subinterface_gwlb_endpoint_inbound[i]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"
  ] }
}

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

resource "aws_iam_role" "vm_series_ec2_iam_role" {
  name               = module.names.iam_role_name["security"]
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

  name = module.names.iam_instance_profile_name["security"]
  role = aws_iam_role.vm_series_ec2_iam_role.name
}

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "vmseries" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  source   = "../../modules/vmseries"

  name             = module.names.vmseries_name[each.key]
  vmseries_version = each.value.common.panos_version

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = module.subnet_sets[v.vpc_subnet].subnets[each.value.az].id
      create_public_ip   = try(v.create_public_ip, false)
    }
  }

  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.value.group])))

  iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}

### SPOKE VM INSTANCES ####

data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.21*-linux-debian-10-x86_64-hvm-ebs-nami"]
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
  name               = module.names.iam_role_name["spoke"]
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

  name = module.names.iam_instance_profile_name["spoke"]
  role = aws_iam_role.spoke_vm_ec2_iam_role.name
}

resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.subnet_sets[each.value.vpc_subnet].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = module.names.vm_name[each.key] }, var.global_tags)
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

### SPOKE INBOUND APPLICATION LOAD BALANCER ###

module "public_alb" {
  source   = "../../modules/alb"
  for_each = var.spoke_albs

  lb_name         = module.names.application_loadbalancer_name[each.key]
  subnets         = { for k, v in module.subnet_sets[each.value.vpc_subnet].subnets : k => { id = v.id } }
  vpc_id          = module.vpc[each.value.vpc].id
  security_groups = [module.vpc[each.value.vpc].security_group_ids[each.value.security_groups]]
  rules = { for k, v in each.value.rules :
    k => merge({
      name = module.names.application_loadbalancer_target_group_name["${each.key}-${k}"]
    }, v)
  }
  targets = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].private_ip }

  tags = var.global_tags
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "public_nlb" {
  source   = "../../modules/nlb"
  for_each = var.spoke_nlbs

  name        = module.names.network_loadbalancer_name[each.key]
  internal_lb = false
  subnets     = { for k, v in module.subnet_sets[each.value.vpc_subnet].subnets : k => { id = v.id } }
  vpc_id      = module.subnet_sets[each.value.vpc_subnet].vpc_id

  balance_rules = { for k, v in each.value.rules :
    k => {
      name        = module.names.network_loadbalancer_target_group_name["${each.key}-${k}"]
      protocol    = v.protocol
      port        = v.port
      target_type = v.target_type
      stickiness  = v.stickiness
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
  }

  tags = var.global_tags
}