data "aws_caller_identity" "current" {}

resource "aws_lb_target_group" "this" {
  for_each           = var.gateway_load_balancers
  protocol    = "GENEVE"
  vpc_id      = var.vpc_id
  target_type = "instance"
  port        = "6081"
  name        = "${var.prefix_name_tag}${each.value.name}"
  health_check {
    port     = "80"
    protocol = "TCP"
  }
  tags                = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_lb_target_group_attachment" "this" {
  for_each         = var.firewalls
  target_group_arn = aws_lb_target_group.this["security-gwlb"].arn //TODO FIX TO LOOP with both FWs and GWLBs MAP
  target_id        = each.value.id
}

resource "aws_lb" "this" {
  for_each           = var.gateway_load_balancers
  name                             = "${var.prefix_name_tag}${each.value.name}"
  load_balancer_type               = "gateway"
  #subnets                          = var.subnet_ids
  subnets = [
    for subnet in each.value.subnet_names :
    var.subnets_map[subnet]
  ]
  enable_cross_zone_load_balancing = true
  lifecycle {
    create_before_destroy = true
  }
  tags                = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_lb_listener" "this" {
  for_each           = var.gateway_load_balancers
  load_balancer_arn = aws_lb.this[each.key].arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}

resource "aws_vpc_endpoint_service" "this" {
  for_each           = var.gateway_load_balancers
  acceptance_required = false
  #allowed_principals         = lookup(each.value, "allowed_principals", null) #["arn:aws:iam::632512868473:root"]
  allowed_principals = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
  gateway_load_balancer_arns = [aws_lb.this[each.key].arn]
  tags                = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_vpc_endpoint" "this" {
  for_each           = var.gateway_load_balancer_endpoints
  service_name      = aws_vpc_endpoint_service.this[each.value.gateway_load_balancer].service_name
  vpc_endpoint_type = aws_vpc_endpoint_service.this[each.value.gateway_load_balancer].service_type
  vpc_id            = var.vpc_id
  subnet_ids = [
    for subnet in each.value.subnet_names :
    var.subnets_map[subnet]
  ]
  tags                = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}