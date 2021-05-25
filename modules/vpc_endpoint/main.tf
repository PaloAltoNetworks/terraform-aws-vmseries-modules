# Be friendly, attempt to use the simplified service name ("s3") to find out a real one ("com.amazonaws.us-west-2.s3").
data "aws_vpc_endpoint_service" "this" {
  count = var.simple_service_name != null ? 1 : 0

  service      = var.simple_service_name
  service_type = var.type
}

#
# Convenient combined object, it is either a `resource` object or a `data` object.
#
locals {
  vpc_endpoint = var.create ? aws_vpc_endpoint.this[0] : data.aws_vpc_endpoint.this[0]
}

resource "aws_vpc_endpoint" "this" {
  count = var.create ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = var.simple_service_name != null ? data.aws_vpc_endpoint_service.this[0].service_name : var.service_name
  vpc_endpoint_type   = var.type
  auto_accept         = var.auto_accept
  policy              = var.policy
  private_dns_enabled = var.private_dns_enabled
  security_group_ids  = var.security_group_ids
  tags                = merge(var.tags, { Name = coalesce(var.name, var.simple_service_name, var.service_name) })
}

data "aws_vpc_endpoint" "this" {
  count = var.create == false ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = var.simple_service_name != null ? data.aws_vpc_endpoint_service.this[0].service_name : var.service_name
  tags         = merge(var.tags, { Name = var.name })
  filter {
    name   = "vpc-endpoint-type"
    values = [var.type]
  }
}

resource "aws_vpc_endpoint_subnet_association" "this" {
  for_each = var.subnets

  vpc_endpoint_id = local.vpc_endpoint.id
  subnet_id       = each.value.id
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  for_each = var.route_table_ids

  vpc_endpoint_id = local.vpc_endpoint.id
  route_table_id  = each.value
}
