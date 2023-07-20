locals {
  vpc              = var.create_vpc ? aws_vpc.this[0] : data.aws_vpc.this[0]
  internet_gateway = var.create_internet_gateway ? aws_internet_gateway.this[0] : var.use_internet_gateway ? data.aws_internet_gateway.this[0] : null
}

# Either use a pre-existing resource or create a new one. So, is it a pre-existing VPC then?
data "aws_vpc" "this" {
  count = var.create_vpc == false ? 1 : 0

  tags = { Name = var.name }
}

# Create a new VPC.
resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                       = var.cidr_block
  tags                             = merge(var.global_tags, var.vpc_tags, { Name = var.name })
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  instance_tenancy                 = var.instance_tenancy
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each = { for _, v in var.secondary_cidr_blocks : v => "ipv4" } # convert list to map

  vpc_id     = local.vpc.id
  cidr_block = each.key
}


############################################################
# DHCP Options
############################################################

resource "aws_vpc_dhcp_options" "this" {
  count = var.create_dhcp_options ? 1 : 0

  domain_name         = var.domain_name
  domain_name_servers = var.domain_name_servers
  ntp_servers         = var.ntp_servers

  tags = merge(var.global_tags, var.vpc_tags, { Name = var.name })
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.create_dhcp_options ? 1 : 0

  vpc_id          = local.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

############################################################
# Internet Gateway
############################################################

# Either use a pre-existing resource or create a new one. So, is it a pre-existing IGW then?
data "aws_internet_gateway" "this" {
  count = var.create_internet_gateway == false && var.use_internet_gateway ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc.id]
  }
  # No filtering by Name Tag here, we assume any existing IGW is good enough.
}

# Create an new IGW.
resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = local.vpc.id
  tags   = merge(var.global_tags, { Name = "${var.name}-igw" })
}

#### Associate RT to IGW for AWS Ingress Routing #### 

resource "aws_route_table" "from_igw" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = local.vpc.id
  tags   = merge(var.global_tags, { Name = "${var.name}-igw" })
}

resource "aws_route_table_association" "from_igw" {
  count = var.create_internet_gateway ? 1 : 0

  route_table_id = aws_route_table.from_igw[0].id
  gateway_id     = local.internet_gateway.id
}

############################################################
# VPN Gateway
############################################################

resource "aws_vpn_gateway" "this" {
  count = var.create_vpn_gateway ? 1 : 0

  vpc_id          = local.vpc.id
  amazon_side_asn = var.vpn_gateway_amazon_side_asn
  tags            = merge(var.global_tags, { Name = "${var.name}-vgw" })
}

#### Dedicated RT for Ingress Routing - Traffic from VGW to us #### 
resource "aws_route_table" "from_vgw" {
  count = var.create_vpn_gateway ? 1 : 0

  vpc_id = local.vpc.id
  tags   = merge(var.global_tags, { Name = "${var.name}-vgw" })
}

resource "aws_route_table_association" "from_vgw" {
  count = var.create_vpn_gateway ? 1 : 0

  gateway_id     = aws_vpn_gateway.this[0].id
  route_table_id = aws_route_table.from_vgw[0].id
}

############################################################
# Network ACLs
############################################################

resource "aws_network_acl" "this" {
  for_each = var.nacls
  vpc_id   = local.vpc.id

  tags = {
    Name = each.value.name
  }
}

locals {
  nacl_rules = flatten([
    for n in keys(var.nacls) : [
      for r in var.nacls[n].rules : {
        nacl        = n
        rule_number = r.rule_number
        egress      = r.egress
        protocol    = r.protocol
        rule_action = r.rule_action
        cidr_block  = r.cidr_block
        from_port   = r.from_port
        to_port     = r.to_port
      }
    ]
  ])
}

resource "aws_network_acl_rule" "this" {
  for_each       = { for nacl_rule in local.nacl_rules : "${nacl_rule.nacl}.${nacl_rule.rule_number}" => nacl_rule }
  network_acl_id = aws_network_acl.this[each.value.nacl].id
  rule_number    = each.value.rule_number
  egress         = each.value.egress
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

############################################################
# Security Groups
############################################################

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.value.name
  description = try(each.value.description, "Security group managed by Terraform")
  vpc_id      = local.vpc.id

  dynamic "ingress" {
    for_each = [
      for rule in each.value.rules :
      rule
      if rule.type == "ingress"
    ]

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      prefix_list_ids = try(ingress.value.prefix_list_ids, null)
      description     = lookup(ingress.value, "description", "")
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in each.value.rules :
      rule
      if rule.type == "egress"
    ]

    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = try(egress.value.cidr_blocks, null)
      prefix_list_ids = try(egress.value.prefix_list_ids, null)
      description     = lookup(egress.value, "description", "")
    }
  }

  tags = merge(var.global_tags, { Name = each.value.name })

  lifecycle {
    create_before_destroy = true
  }
}
