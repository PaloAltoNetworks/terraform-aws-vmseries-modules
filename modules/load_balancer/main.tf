# TODO
# # figure out how to join to maps: vms vs ports->protocols, so that targert groups contain always all FWs

locals {
  subnet_ids = { for k,v in var.subnet_set_subnets: k => v.id }
}

resource "aws_eip" "this" {
  for_each = local.subnet_ids

  # tags = merge({ Name = "fosix_eip_nat" }, var.tags)
  tags = { Name = "fosix_lb_eip_${each.key}" }
}

resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.internal_lb
  load_balancer_type               = var.create_application_lb ? "application" : "network"
  # subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  dynamic "subnet_mapping" {
    for_each = local.subnet_ids

    content {
      subnet_id     = subnet_mapping.value
      allocation_id = aws_eip.this[subnet_mapping.key].id
    }
  }


  # tags = {
  #   Environment = "production"
  # }
}

resource "aws_lb_target_group" "this" {
  for_each = var.balance_rules

  name     = "target-group-${each.key}"
  vpc_id   = var.vpc_id
  port     = each.value.port
  protocol = each.value.proto
}

locals {
  balance_rules_list = [
    for k,v in var.balance_rules: {
      key = k
      proto = v.proto
      port = v.port
    }
  ]

  fw_instance_ids_list = [
    for k,v in var.fw_instance_ids : {
      name = k
      id = v
    }
  ]

  combined_rules_instances = {
    for v in setproduct (local.balance_rules_list, local.fw_instance_ids_list) : 
      "${v[0].key}-${v[1].name}" => {
        app_name = v[0].key
        port = v[0].port
        proto = v[0].proto
        instance_id = v[1].id
      }
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = local.combined_rules_instances

  target_group_arn = aws_lb_target_group.this[each.value.app_name].arn
  target_id        = each.value.instance_id
  port             = each.value.port
}

resource "aws_lb_listener" "this" {
  for_each = var.balance_rules

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.proto

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}
