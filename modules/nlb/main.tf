locals {
  # this is a map of subnet IDs where key is set to the zone name
  # example:
  #  us-east-1a     : some_id
  subnet_ids = { for k, v in var.subnet_set_subnets : k => v.id }
}

resource "aws_eip" "this" {
  for_each = var.lb_dedicated_ips && !var.internal_lb ? local.subnet_ids : {}

  tags = merge({ Name = "${var.lb_name}_eip_${each.key}" }, var.tags)
}

resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.internal_lb
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # if we relay on AWS to manage public IPs we use subnets to attach a LB with a subnet
  subnets = var.lb_dedicated_ips && !var.internal_lb ? null : [for set, id in local.subnet_ids : id]
  # if we would like to create our own EIPs, we need to assign them to a subnet explicitly, therefore we us subnet mapping
  dynamic "subnet_mapping" {
    for_each = var.lb_dedicated_ips && !var.internal_lb ? local.subnet_ids : {}

    content {
      subnet_id     = subnet_mapping.value
      allocation_id = aws_eip.this[subnet_mapping.key].id
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.balance_rules

  name        = "target-group-${each.key}"
  vpc_id      = var.vpc_id
  port        = try(each.value.target_port, each.value.port)
  protocol    = each.value.protocol
  target_type = each.value.target_type


  health_check {
    healthy_threshold   = try(each.value.threshold, null)
    unhealthy_threshold = try(each.value.threshold, null)
    interval            = try(each.value.interval, null)
    protocol            = "TCP"
    port                = try(each.value.health_check_port, "traffic-port")
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness && each.value.protocol != "TLS" ? [1] : []

    content {
      enabled = true
      type    = "source_ip"
    }
  }


  tags = var.tags
}

# target_attachments is a flattened version of `var.balance_rules` 
#  it contains maps of target attachment properties
#  each map contains target id + port + a name of the app rule which is a key used
#  to reference the actual target group instance
locals {
  fw_instance_list = distinct(flatten([
    for k, v in var.balance_rules : [
      for target_name, target_id in v.targets :
      {
        app_name = k
        name     = target_name
        id       = target_id
        port     = try(v.target_port, v.port)
      }
    ]
  ]))

  target_attachments = {
    for v in local.fw_instance_list :
    "${v.app_name}-${v.name}" => {
      app_name = v.app_name
      id       = v.id
      port     = v.port
    }
  }
}

resource "aws_lb_target_group_attachment" "this" {
  # for_each = local.target_attachments
  for_each = {
    for v in local.fw_instance_list :
    "${v.app_name}-${v.name}" => {
      app_name = v.app_name
      id       = v.id
      port     = v.port
    }
  }

  target_group_arn = aws_lb_target_group.this[each.value.app_name].arn
  target_id        = each.value.id
  port             = each.value.port
}

resource "aws_lb_listener" "this" {
  for_each = var.balance_rules

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  # the values below is for TLS probes only
  certificate_arn = each.value.protocol == "TLS" ? try(each.value.certificate_arn, null) : null
  alpn_policy     = each.value.protocol == "TLS" ? try(each.value.alpn_policy, null) : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = var.tags
}
