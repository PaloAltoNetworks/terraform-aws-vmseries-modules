locals {
  # `target_attachments` is a flattened version of `var.balance_rules`, it contains maps of target attachments' properties.
  # Each map contains target `id`, `port` and `app_name`, which is a key used to reference the actual target group instance.
  # It is used only for `aws_lb_target_group_attachment` resource.
  fw_instance_list = flatten([
    for k, v in var.balance_rules : [
      for target_name, target_id in v.targets :
      {
        app_name = k
        name     = target_name
        id       = target_id
        port     = try(v.target_port, try(v.port, v.protocol == "HTTP" ? "80" : "443"))
      }
    ]
  ])

  target_attachments = {
    for v in local.fw_instance_list :
    "${v.app_name}-${v.name}" => {
      app_name = v.app_name
      id       = v.id
      port     = v.port
    }
  }
}

# ## Access Logs Bucket ##
resource "aws_s3_bucket" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket        = var.access_logs_s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  acl    = "private"
}

data "aws_iam_policy_document" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = [var.elb_account_ids[var.region]]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${aws_s3_bucket.this[0].id}/AWSLogs/*"]
    # resources = ["arn:aws:s3:::${aws_s3_bucket.this[0].id}/${var.access_logs_s3_bucket_prefix}/AWSLogs/"]
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}

data "aws_s3_bucket" "this" {
  count = var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket = var.access_logs_s3_bucket_name
}
###########################

resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = false
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # some application load balancer specifics
  drop_invalid_header_fields = true
  idle_timeout               = 30
  desync_mitigation_mode     = var.desync_mitigation_mode
  security_groups            = var.security_groups

  subnets = [for k, v in var.subnets : v.id]

  dynamic "access_logs" {
    for_each = var.configure_access_logs ? [1] : []

    content {
      bucket  = var.access_logs_byob ? data.aws_s3_bucket.this[0].id : aws_s3_bucket.this[0].id
      prefix  = var.access_logs_s3_bucket_prefix
      enabled = true
    }
  }

  tags = var.tags

  depends_on = [
    aws_s3_bucket_policy.this[0]
  ]
}

resource "aws_lb_target_group" "this" {
  for_each = var.balance_rules

  name                          = "${var.lb_name}-tg-${each.key}"
  vpc_id                        = var.vpc_id
  port                          = try(each.value.target_port, try(each.value.port, each.value.protocol == "HTTP" ? "80" : 443))
  protocol                      = each.value.protocol
  protocol_version              = try(each.value.protocol_version, null)
  target_type                   = "ip"
  load_balancing_algorithm_type = try(each.value.round_robin, null) != null ? (each.value.round_robin ? "round_robin" : "least_outstanding_requests") : "round_robin"

  health_check {
    healthy_threshold   = try(each.value.health_check_healthy_threshold, null)
    unhealthy_threshold = try(each.value.health_check_unhealthy_threshold, null)
    interval            = try(each.value.health_check_interval, null)
    protocol            = try(each.value.health_check_protocol, each.value.protocol)
    port                = try(each.value.health_check_port, "traffic-port")
    matcher             = try(each.value.health_check_matcher, null)
    path                = try(each.value.health_check_path, "/")
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = local.target_attachments

  target_group_arn = aws_lb_target_group.this[each.value.app_name].arn
  target_id        = each.value.id
  port             = each.value.port
}

resource "aws_lb_listener" "this" {
  for_each = var.balance_rules

  load_balancer_arn = aws_lb.this.arn
  port              = try(each.value.port, each.value.protocol == "HTTP" ? "80" : "443")
  protocol          = each.value.protocol

  # HTTPS specific values
  certificate_arn = each.value.protocol == "HTTPS" ? try(each.value.certificate_arn, null) : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = var.tags
}

