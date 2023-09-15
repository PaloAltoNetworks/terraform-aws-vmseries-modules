locals {
  eips         = var.create_eip ? aws_eip.this : data.aws_eip.this
  nat_gateways = var.create_nat_gateway ? aws_nat_gateway.this : data.aws_nat_gateway.this
}

#
# Elastic IPs: either new or pre-existing.
#
resource "aws_eip" "this" {
  for_each = var.create_eip && var.create_nat_gateway ? var.subnets : {}

  domain = "vpc"
  tags = merge(
    var.global_tags,
    { Name = coalesce(try(var.eips[each.key].name, null), try(each.value.tags.Name, null), "natgw-${each.key}") },
    var.eip_tags
  )
}

data "aws_eip" "this" {
  for_each = var.create_eip == false && var.create_nat_gateway ? var.eips : {}

  id        = try(each.value.id, null)
  public_ip = try(each.value.public_ip, null)
  tags      = merge(var.eip_tags, try(each.value.name, null) != null ? { Name = each.value.name } : {})
}

#
# NAT Gateways: either new or pre-existing.
#
resource "aws_nat_gateway" "this" {
  for_each = var.create_nat_gateway ? var.subnets : {}

  allocation_id = local.eips[each.key].id
  subnet_id     = each.value.id
  tags = merge(
    # First take the general tags,
    var.global_tags,
    # ...override name with a sane default,
    { Name = "natgw-${each.key}" },
    # ...now attempt to override again - to the same name as the owning subnet,
    try({ Name = each.value.tags.Name }, {}),
    # ...in the end, custom tags prevail.
    var.nat_gateway_tags,
    try({ Name = var.nat_gateway_names[each.key] }, {})
  )
}

data "aws_nat_gateway" "this" {
  for_each = var.create_nat_gateway == false ? var.subnets : {}

  subnet_id = each.value.id
  state     = "available"
  tags = merge(
    var.nat_gateway_tags,
    try({ Name = var.nat_gateway_names[each.key] }, {})
  )
}
