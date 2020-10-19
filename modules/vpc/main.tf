################
# Locals to combine data source and resource references for optional browfield support
################


####  VPC #### 
locals {
  existing_vpc = {
    for k, vpc in data.aws_vpc.this :
    "vpc_id" => vpc.id
  }

  new_vpc = {
    for k, vpc in aws_vpc.this :
    "vpc_id" => vpc.id
  }

  combined_vpc = merge(local.existing_vpc, local.new_vpc)
}

data "aws_vpc" "this" {
  for_each = {
    for k, vpc in var.vpc : k => vpc
    if lookup(vpc, "existing", null) == true ? true : false
  }
  tags = {
    Name = each.value.name
  }
}

####  Subnets #### 
locals {
  existing_subnets = {
    for k, subnet in data.aws_subnet.this :
    k => subnet.id
  }

  new_subnets = {
    for k, subnet in aws_subnet.this :
    k => subnet.id
  }

  combined_subnets = merge(local.existing_subnets, local.new_subnets)
}

data "aws_subnet" "this" {
  for_each = {
    for k, subnet in var.subnets : k => subnet
    if lookup(subnet, "existing", null) == true ? true : false
  }
  tags = {
    Name = "${var.prefix_name_tag}${each.value.name}"
  }
}

################
# Resource Creation
################

#### Create VPC resources #### 

resource "aws_vpc" "this" {
  for_each = {
    for k, vpc in var.vpc : k => vpc
    if lookup(vpc, "existing", null) != true ? true : false
  }
  cidr_block           = each.value.cidr_block
  tags                 = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
  enable_dns_hostnames = lookup(each.value, "enable_dns_hostnames", null)
  enable_dns_support   = lookup(each.value, "enable_dns_support", null)
  instance_tenancy     = lookup(each.value, "instance_tenancy", null)
}

locals { // Create new list of optional secondary_cidr_blocks if key exists in var.vpc
  secondary_cidr_blocks = flatten([
    for vpc in var.vpc : [
      for cidr in toset(vpc.secondary_cidr_blocks) : {
        vpc  = vpc.name
        cidr = cidr
      }
    ]
    if lookup(vpc, "secondary_cidr_blocks", null) != null ? true : false
  ])
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each   = { for value in local.secondary_cidr_blocks : "${value.vpc}-${value.cidr}" => value }
  vpc_id     = local.combined_vpc["vpc_id"]
  cidr_block = each.value.cidr
}

#### Create IGW #### 

resource "aws_internet_gateway" "this" {
  for_each = {
    for k, vpc in var.vpc : k => vpc
    if lookup(vpc, "internet_gateway", null) == null ? true : vpc.internet_gateway // Defaults to true if not specified
  }
  vpc_id = local.combined_vpc["vpc_id"]
  tags   = merge({ Name = "${var.prefix_name_tag}igw" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

#### Create Subnets ####

resource "aws_subnet" "this" {
  for_each = {
    for k, subnet in var.subnets : k => subnet
    if lookup(subnet, "existing", null) != true ? true : false
  }
  cidr_block        = each.value.cidr
  availability_zone = lookup(each.value, "az", null)
  tags              = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
  vpc_id            = local.combined_vpc["vpc_id"]
  depends_on        = [aws_vpc_ipv4_cidr_block_association.this]
}

#### Create and associate Route tables #### 

resource "aws_route_table" "this" {
  for_each = var.vpc_route_tables
  vpc_id   = local.combined_vpc["vpc_id"]
  tags     = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_route_table_association" "this" {
  for_each = {
    for k, subnet in var.subnets : k => subnet
    if lookup(subnet, "existing", null) != true ? true : false
  }
  subnet_id      = local.combined_subnets[each.key]
  route_table_id = aws_route_table.this[each.value.rt].id
}

############################################################
# NAT Gateways
############################################################

resource "aws_eip" "nat_eip" {
  for_each = var.nat_gateways
  vpc      = true
  tags     = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_nat_gateway" "this" {
  for_each      = var.nat_gateways
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = local.combined_subnets[each.key]
  tags          = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

############################################################
# VPN Gateways
############################################################

resource "aws_vpn_gateway" "this" {
  for_each        = var.vpn_gateways
  vpc_id          = lookup(each.value, "vpc_attached", null) != false ? local.combined_vpc["vpc_id"] : null // Default is to attach to VPC
  amazon_side_asn = each.value.amazon_side_asn
  tags            = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_dx_gateway_association" "this" {
  for_each              = { for name, vgw in var.vpn_gateways : name => vgw if contains(keys(vgw), "dx_gateway_id") }
  dx_gateway_id         = each.value.dx_gateway_id
  associated_gateway_id = aws_vpn_gateway.this[each.key].id
}

#### Optionally enable VGW Propogation for Route Tables #### 

resource "aws_vpn_gateway_route_propagation" "this" {
  for_each       = { for name, rt in var.vpc_route_tables : name => rt if contains(keys(rt), "vgw_propagation") }
  vpn_gateway_id = aws_vpn_gateway.this[each.value.vgw_propagation].id
  route_table_id = aws_route_table.this[each.key].id
}

#### Associate RT to VGW for AWS Ingress Routing #### 

resource "aws_route_table_association" "vgw_ingress" {
  for_each       = { for name, rt in var.vpc_route_tables : name => rt if contains(keys(rt), "vgw_association") }
  route_table_id = aws_route_table.this[each.key].id
  gateway_id     = aws_vpn_gateway.this[each.value.vgw_association].id
}

#### Associate RT to IGW for AWS Ingress Routing #### 

resource "aws_route_table_association" "igw_ingress" {
  for_each       = { for name, rt in var.vpc_route_tables : name => rt if contains(keys(rt), "igw_association") }
  route_table_id = aws_route_table.this[each.key].id
  gateway_id     = aws_internet_gateway.this[each.value.igw_association].id
}


############################################################
# Security Groups
############################################################

resource "aws_security_group" "this" {
  for_each = var.security_groups
  name     = "${var.prefix_name_tag}${each.value.name}"
  vpc_id   = local.combined_vpc["vpc_id"]

  dynamic "ingress" {
    for_each = [
      for rule in each.value.rules :
      rule
      if rule.type == "ingress"
    ]

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", "")
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in each.value.rules :
      rule
      if rule.type == "egress"
    ]

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = lookup(egress.value, "description", "")
    }
  }

  tags = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))

  lifecycle {
    create_before_destroy = true
  }
}


############################################################
# VPC Endpoints
############################################################

// TODO: Add support for optional policy attachment
// TODO: Better way to detect service_names for different endpoint / regions?

resource "aws_vpc_endpoint" "interface" {
  for_each = {
    for k, endpoint in var.vpc_endpoints : k => endpoint
    if lookup(endpoint, "vpc_endpoint_type", null) == "Interface" ? true : false
  }
  vpc_id            = local.combined_vpc["vpc_id"]
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type
  security_group_ids = [
    for sg in each.value.security_groups :
    aws_security_group.this[sg].id
  ]
  subnet_ids = [
    for subnet in each.value.subnet_ids :
    local.combined_subnets[subnet]
  ]
  private_dns_enabled = lookup(each.value, "private_dns_enabled", null)
  tags                = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = {
    for k, endpoint in var.vpc_endpoints : k => endpoint
    if lookup(endpoint, "vpc_endpoint_type", null) == "Gateway" ? true : false
  }
  vpc_id            = local.combined_vpc["vpc_id"]
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type
  route_table_ids = [
    for rt in each.value.route_table_ids :
    aws_route_table.this[rt].id
  ]
  private_dns_enabled = lookup(each.value, "private_dns_enabled", null)
  tags                = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}
