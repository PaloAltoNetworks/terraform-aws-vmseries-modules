locals {
  # this is a map of subnet IDs where key is set to the zone name
  # example:
  #  us-east-1a     : some_id
  subnet_ids = { for k, v in var.subnet_set_subnets : k => v.id }
}

resource "aws_eip" "this" {
  for_each = var.lb_dedicated_ips ? local.subnet_ids : {}

  tags = merge({ Name = "${var.lb_name}_eip_${each.key}" }, var.tags)
}

resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.internal_lb
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # if we relay on AWS to manage public IPs we use subnets to attach a LB with a subnet
  subnets = var.lb_dedicated_ips ? null : [for set, id in local.subnet_ids : id]
  # if we would like to create our own EIPs, we need to assign them to a subnet explicitly, therefore we us subnet mapping
  dynamic "subnet_mapping" {
    for_each = var.lb_dedicated_ips ? local.subnet_ids : {}

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
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = "ip"

  health_check {
    healthy_threshold   = try(each.value.threshold, null)
    unhealthy_threshold = try(each.value.threshold, null)
    interval            = try(each.value.interval, null)
    protocol            = "TCP"
    port                = try(each.value.health_check_port, each.value.port)

  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  tags = var.tags
}

# combined_rules_instances is a combination of balance_rules and all FW instances
#  this map will contains  each rule vs each instance 
#  something we can use with group attachmemt, where we need to specify each rule data for
#  each instance. 
locals {
  balance_rules_list = [
    for k, v in var.balance_rules : {
      key   = k
      proto = v.protocol
      port  = v.port
    }
  ]

  fw_instance_ips_list = [
    for k, v in var.fw_instance_ips : {
      name = k
      ip   = v
    }
  ]

  combined_rules_instances = {
    for v in setproduct(local.balance_rules_list, local.fw_instance_ips_list) :
    "${v[0].key}-${v[1].name}" => {
      app_name    = v[0].key
      port        = v[0].port
      proto       = v[0].proto
      instance_ip = v[1].ip
    }
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = local.combined_rules_instances

  target_group_arn = aws_lb_target_group.this[each.value.app_name].arn
  target_id        = each.value.instance_ip
  port             = each.value.port
}

resource "aws_lb_listener" "this" {
  for_each = var.balance_rules

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = var.tags
}
