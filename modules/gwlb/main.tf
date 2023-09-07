data "aws_caller_identity" "current" {}

# The GWLB.
resource "aws_lb" "this" {
  name                             = var.name
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true
  subnets                          = [for v in var.subnets : v.id]
  tags                             = merge(var.global_tags, { Name = var.name }, var.lb_tags)
  enable_deletion_protection       = var.enable_lb_deletion_protection
  lifecycle {
    create_before_destroy = true
  }
}

# The Service which accepts traffic from Endpoints ("clients") located on any VPCs.
# One service is possible per one gwlb.
resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.this.arn]
  tags                       = merge(var.global_tags, { Name = var.name }, var.endpoint_service_tags)

  # Workaround for: error waiting for VPC Endpoint (vpce-00777c35bf9ae9c53) to become available: VPC Endpoint is in a failed state
  depends_on = [aws_lb.this]
}

# Dedicated resource for allowing principals, this allows for adding more principals from outside this module (Onboarding new AWS accounts adhoc)
resource "aws_vpc_endpoint_service_allowed_principal" "this" {
  for_each                = toset(coalescelist(var.allowed_principals, ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]))
  vpc_endpoint_service_id = aws_vpc_endpoint_service.this.id
  principal_arn           = each.key
}

# The GWLB Listener.
# One listener is possible for one gwlb, else it fails with "DuplicateListener: A listener already exists on this port for this load balancer".
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  # tags = merge(var.global_tags, { Name = var.name }, var.lb_tags)    would require aws provider v3.40.0
}

# Target Group
# One target group is possible for one gwlb, or else it fails with "You cannot specify multiple target groups in a single action with a load balancer of type 'gateway'".
resource "aws_lb_target_group" "this" {
  name                 = try(var.tg_name, var.name)
  vpc_id               = var.vpc_id
  target_type          = "instance"
  protocol             = "GENEVE"
  port                 = "6081"
  deregistration_delay = var.deregistration_delay
  # Tags were accepted on old aws providers starting from v3.18, but since v3.49 they fail with
  # "You cannot specify tags on creation of a GENEVE target group".
  # https://github.com/hashicorp/terraform-provider-aws/issues/20144
  #
  # tags = merge(var.global_tags, { Name = var.name }, var.lb_target_group_tags)
  tags = var.lb_target_group_tags

  health_check {
    enabled             = var.health_check_enabled
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }

  stickiness {
    enabled = var.stickiness_type != null
    type    = coalesce(var.stickiness_type, "source_ip_dest_ip_proto")
  }
}

# Attach one or more Targets (EC2 Instances).
resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_instances

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value.id
}
