resource "aws_lb_target_group" "this" {
  protocol    = "GENEVE"
  vpc_id      = var.vpc_id
  target_type = "instance"
  port        = "6081"
  name        = "${var.prefix_name_tag}${var.name}"
  health_check {
    port     = "80"
    protocol = "TCP"
  }
  tags = var.tags
}



resource "aws_lb_target_group_attachment" "this" {
  for_each         = var.firewalls
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value.id
}



resource "aws_lb" "this" {
  name                             = "${var.prefix_name_tag}${var.name}"
  load_balancer_type               = "gateway"
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = true
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}



resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}



resource "aws_vpc_endpoint_service" "this" {
  acceptance_required = false
  allowed_principals         = var.allowed_principals #["arn:aws:iam::632512868473:root"]
  gateway_load_balancer_arns = [aws_lb.this.arn]
  tags = merge(
    { "Name" = "kbechler-gwlb01" },
    var.tags
  )
}



resource "aws_vpc_endpoint" "this" {
  count             = length(var.subnet_ids)
  service_name      = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type = aws_vpc_endpoint_service.this.service_type
  vpc_id            = var.vpc_id
  subnet_ids        = [var.subnet_ids[count.index]]
}
