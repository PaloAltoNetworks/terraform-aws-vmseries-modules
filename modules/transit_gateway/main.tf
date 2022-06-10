###########################################################################################
# Locals to uniformly combine both the newly created objects and the pre-existing objects.
# The former are `resources`, the latter are `data` for Terraform.
###########################################################################################

locals {
  transit_gateway              = var.create ? aws_ec2_transit_gateway.this[0] : data.aws_ec2_transit_gateway.this[0]
  transit_gateway_route_tables = { for k, v in var.route_tables : k => v.create ? aws_ec2_transit_gateway_route_table.this[k] : data.aws_ec2_transit_gateway_route_table.this[k] }
}

##############################################################################
# Transit Gateway (TGW)
##############################################################################

resource "aws_ec2_transit_gateway" "this" {
  count = var.create ? 1 : 0

  amazon_side_asn                 = var.asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support
  tags                            = merge(var.tags, { Name = var.name })
}

data "aws_ec2_transit_gateway" "this" {
  count = var.create == false ? 1 : 0

  # ID of an existing TGW. By default set to `null` hence can be referenced directly.
  id = var.id
  # Filtering existing TGWs by name, only in case no ID was provided.
  dynamic "filter" {
    for_each = var.id == null ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.name]

    }
  }
}

#### Route Tables ####

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = { for k, v in var.route_tables : k => v if v.create }

  transit_gateway_id = local.transit_gateway.id
  tags               = merge(var.tags, lookup(each.value, "local_tags", {}), { Name = coalesce(lookup(each.value, "name", ""), var.name) })
}

data "aws_ec2_transit_gateway_route_table" "this" {
  for_each = { for k, v in var.route_tables : k => v if v.create == false }

  filter {
    name   = "transit-gateway-id"
    values = [local.transit_gateway.id]
  }

  filter {
    name   = "tag:Name"
    values = [each.value.name]
  }
}

##############################################################################
# Resource Shares for TGW
##############################################################################

# Create Resource Share if shared_principals contains any entries.
resource "aws_ram_resource_share" "this" {
  count = length(var.shared_principals) != 0 ? 1 : 0

  name                      = coalesce(var.ram_resource_share_name, var.name)
  tags                      = merge(var.tags, { Name = coalesce(var.ram_resource_share_name, var.name) })
  allow_external_principals = true
}

# Associate TGW to the Share.
resource "aws_ram_resource_association" "this" {
  count = length(var.shared_principals) != 0 ? 1 : 0

  resource_arn       = local.transit_gateway.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

# Associate each Account to the Share.
resource "aws_ram_principal_association" "this" {
  for_each = var.shared_principals

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this[0].arn
}
