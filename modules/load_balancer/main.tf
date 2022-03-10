# TODO
# # figure out what should we do with public IPs: internet gateway? or EIPs?
# # figure out how to join to maps: vms vs ports->protocols, so that targert groups contain always all FWs

resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.internal_lb
  load_balancer_type               = var.create_application_lb ? "application" : "network"
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # tags = {
  #   Environment = "production"
  # }
}

resource "aws_lb_target_group" "this" {
  for_each = var.balance_ports

  name     = "target-group-${aws_lb.this.name}"
  vpc_id   = var.vpc_id
  port     = each.value
  protocol = each.key
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.balance_ports

  target_group_arn = aws_lb_target_group.this[each.key].arn
  target_id        = var.fw_instance_id
  port             = each.value
}

resource "aws_lb_listener" "this" {
  for_each = var.balance_ports

  load_balancer_arn = aws_lb.this.arn
  port              = each.value
  protocol          = each.key

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}
