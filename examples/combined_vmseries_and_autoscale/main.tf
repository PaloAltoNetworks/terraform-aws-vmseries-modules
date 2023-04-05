### SECURITY VPC ###

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

module "subnet_sets" {
  # The "set" here means we will repeat in each AZ an identical/similar subnet.
  # The notion of "set" is used a lot here, it extends to nat gateways, routes, routes' next hops,
  # gwlb endpoints and any other resources which would be a single point of failure when placed
  # in a single AZ.
  for_each = toset(flatten([for k, v in { for vk, vv in var.vpcs : vk => distinct([for sk, sv in vv.subnets : format("%s-%s", vk, sv.set)]) } : v]))
  source   = "PaloAltoNetworks/vmseries-modules/aws//modules/subnet_set"
  version  = "0.4.1"

  name                = split("-", each.key)[1]
  vpc_id              = module.vpc[split("-", each.key)[0]].id
  has_secondary_cidrs = module.vpc[split("-", each.key)[0]].has_secondary_cidrs
  cidrs               = one([for vk, vv in var.vpcs : { for sk, sv in vv.subnets : sk => sv if endswith(each.key, sv.set) } if startswith(each.key, vk)])
}

### NATGW ###

module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
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
  count                          = var.panorama.transit_gateway_attachment_id != null ? 1 : 0
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_security_vpc"].id
  transit_gateway_attachment_id  = var.panorama.transit_gateway_attachment_id
  destination_cidr_block         = var.panorama.vpc_cidr
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

module "gwlbe_endpoint" {
  source = "../../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = "${var.name_prefix}${each.value.name}"
  gwlb_service_name = module.gwlb[each.value.gwlb].endpoint_service.service_name
  vpc_id            = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets           = module.subnet_sets[each.value.vpc_subnet].subnets
}

### SECURITY VPC ROUTES ###

locals {
  security_vpc_routes_outbound_source_cidrs = [
    # outbound traffic return after inspection
    "10.0.0.0/8",
  ]
  security_vpc_routes_outbound_destin_cidrs = [
    # outbound traffic incoming for inspection from TGW
    "0.0.0.0/0",
  ]
  security_vpc_routes_eastwest_cidrs = [
    # eastwest traffic incoming for inspection from TGW
    "10.0.0.0/8",
  ]
  security_vpc_mgmt_routes_to_tgw = [
    # Panorama via TGW (must not repeat any security_vpc_routes_eastwest_cidrs)
    "10.255.0.0/16",
  ]

  vpc_routes = concat(
    [for cidr in local.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "security_vpc-mgmt"
        next_hop_set = module.vpc["security_vpc"].igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "security_vpc-lambda"
        next_hop_set = module.natgw_set["security_nat_gw"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in concat(local.security_vpc_routes_eastwest_cidrs, local.security_vpc_mgmt_routes_to_tgw) :
      {
        subnet_key   = "security_vpc-mgmt"
        next_hop_set = module.transit_gateway_attachment["security"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in concat(local.security_vpc_routes_eastwest_cidrs, local.security_vpc_mgmt_routes_to_tgw) :
      {
        subnet_key   = "security_vpc-lambda"
        next_hop_set = module.transit_gateway_attachment["security"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_eastwest_cidrs :
      {
        subnet_key   = "security_vpc-tgw_attach"
        next_hop_set = module.gwlbe_endpoint["security_gwlb_eastwest"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "security_vpc-tgw_attach"
        next_hop_set = module.gwlbe_endpoint["security_gwlb_outbound"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "security_vpc-public"
        next_hop_set = module.natgw_set["security_nat_gw"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_outbound_source_cidrs :
      {
        subnet_key   = "security_vpc-gwlbe_outbound"
        next_hop_set = module.transit_gateway_attachment["security"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_eastwest_cidrs :
      {
        subnet_key   = "security_vpc-gwlbe_eastwest"
        next_hop_set = module.transit_gateway_attachment["security"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "security_vpc-natgw"
        next_hop_set = module.vpc["security_vpc"].igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in local.security_vpc_routes_outbound_source_cidrs :
      {
        subnet_key   = "security_vpc-natgw"
        next_hop_set = module.gwlbe_endpoint["security_gwlb_outbound"].next_hop_set
        to_cidr      = cidr
      }
    ],
    [
      {
        subnet_key   = "app1_vpc-app1_gwlbe"
        next_hop_set = module.vpc["app1_vpc"].igw_as_next_hop_set
        to_cidr      = "0.0.0.0/0"
      },
      {
        subnet_key   = "app1_vpc-app1_vm"
        next_hop_set = module.transit_gateway_attachment["app1"].next_hop_set
        to_cidr      = "0.0.0.0/0"
      },
      {
        subnet_key   = "app1_vpc-app1_lb"
        next_hop_set = module.gwlbe_endpoint["app1_inbound"].next_hop_set
        to_cidr      = "0.0.0.0/0"
      }
    ],
    [
      {
        subnet_key   = "app2_vpc-app2_gwlbe"
        next_hop_set = module.vpc["app2_vpc"].igw_as_next_hop_set
        to_cidr      = "0.0.0.0/0"
      },
      {
        subnet_key   = "app2_vpc-app2_vm"
        next_hop_set = module.transit_gateway_attachment["app2"].next_hop_set
        to_cidr      = "0.0.0.0/0"
      },
      {
        subnet_key   = "app2_vpc-app2_lb"
        next_hop_set = module.gwlbe_endpoint["app2_inbound"].next_hop_set
        to_cidr      = "0.0.0.0/0"
      }
    ]
  )
}

module "vpc_routes" {
  for_each = { for route in local.vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "PaloAltoNetworks/vmseries-modules/aws//modules/vpc_route"
  version  = "0.4.1"

  route_table_ids = module.subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
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

resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.subnet_sets[each.value.vpc_subnet].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "app_lb" {
  source = "../../modules/nlb"

  for_each = var.spoke_lbs

  name        = "${var.name_prefix}${each.key}"
  internal_lb = false
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
  subinterface_gwlb_endpoint_eastwest = { for i, j in var.vmseries_asgs : i => join(",", compact(concat([
    for k, v in module.gwlbe_endpoint["security_gwlb_eastwest"].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, j.subinterfaces.eastwest)
  ]))) }
  subinterface_gwlb_endpoint_outbound = { for i, j in var.vmseries_asgs : i => join(",", compact(concat([
    for k, v in module.gwlbe_endpoint["security_gwlb_outbound"].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, j.subinterfaces.outbound)
  ]))) }
  subinterface_gwlb_endpoint_inbound1 = { for i, j in var.vmseries_asgs : i => join(",", compact(concat([
    for k, v in module.gwlbe_endpoint["app1_inbound"].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, j.subinterfaces.inbound1)
  ]))) }
  subinterface_gwlb_endpoint_inbound2 = { for i, j in var.vmseries_asgs : i => join(",", compact(concat([
    for k, v in module.gwlbe_endpoint["app2_inbound"].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, j.subinterfaces.inbound2)
  ]))) }
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => format("%s,%s,%s,%s,%s", j.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest[i], local.subinterface_gwlb_endpoint_outbound[i], local.subinterface_gwlb_endpoint_inbound1[i], local.subinterface_gwlb_endpoint_inbound2[i]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"
  ] }
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

  for_each = var.vmseries_asgs

  ssh_key_name                  = var.ssh_key_name
  region                        = var.region
  name_prefix                   = var.name_prefix
  global_tags                   = var.global_tags
  vmseries_version              = each.value.panos_version
  max_size                      = each.value.asg_max_size
  min_size                      = each.value.asg_min_size
  desired_capacity              = each.value.asg_desired_cap
  vmseries_iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  subnet_ids                    = [for i, j in var.vpcs[each.value.vpc].subnets : module.subnet_sets[format("%s-lambda", each.value.vpc)].subnets[j.az].id if j.set == "lambda"]
  security_group_ids            = [module.vpc[each.value.vpc].security_group_ids["lambda"]]
  interfaces = {
    for k, v in each.value.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.vpc[each.value.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = { for z, c in v.subnet : c => module.subnet_sets[format("%s-%s", each.value.vpc, k)].subnets[c].id }
      create_public_ip   = try(v.create_public_ip, false)
    }
  }
  ebs_kms_id        = each.value.ebs_kms_id
  target_group_arn  = module.gwlb[each.value.gwlb].target_group.arn
  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.key])))

  scaling_plan_enabled         = each.value.scaling_plan_enabled
  scaling_metric_name          = each.value.scaling_metric_name
  scaling_tags                 = each.value.scaling_tags
  scaling_target_value         = each.value.scaling_target_value
  scaling_cloudwatch_namespace = each.value.scaling_cloudwatch_namespace
}
