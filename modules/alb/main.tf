locals {
  rules_flattened = flatten([
    for k, v in var.rules : [
      for l_k, l_v in v.listener_rules : {
        tg_key                   = "${k}-${l_v.target_port}"
        app_name                 = k
        port                     = l_v.target_port
        proto                    = l_v.target_protocol
        proto_v                  = try(l_v.target_protocol_version, null)
        h_ch_healthy_threshold   = try(v.health_check_healthy_threshold, null)
        h_ch_unhealthy_threshold = try(v.health_check_unhealthy_threshold, null)
        h_ch_interval            = try(v.health_check_interval, null)
        h_ch_timeout             = try(v.health_check_timeout, null)
        h_ch_protocol            = try(v.health_check_protocol, v.protocol)
        h_ch_port                = try(v.health_check_port, "traffic-port")
        h_ch_matcher             = try(v.health_check_matcher, null)
        h_ch_path                = try(v.health_check_path, "/")
        lb_algorithm             = try(v.round_robin, null) != null ? (v.round_robin ? "round_robin" : "least_outstanding_requests") : "round_robin"
        priority                 = l_k
        host_headers             = try(l_v.host_headers, null)
        http_headers             = try(l_v.http_headers, null)
      }
    ]
  ])

  listener_rules = {
    for v in local.rules_flattened : "${v.app_name}-${v.priority}" => {
      listener_key = v.app_name
      priority     = v.priority
      tg_key       = v.tg_key
      host_headers = v.host_headers
      http_headers = v.http_headers
    }
  }

  listener_tg = {
    for v in local.rules_flattened : v.tg_key => {
      port                     = v.port
      proto                    = v.proto
      proto_v                  = v.proto_v
      h_ch_healthy_threshold   = v.h_ch_healthy_threshold
      h_ch_unhealthy_threshold = v.h_ch_unhealthy_threshold
      h_ch_interval            = v.h_ch_interval
      h_ch_timeout             = v.h_ch_timeout
      h_ch_protocol            = v.h_ch_protocol
      h_ch_port                = v.h_ch_port
      h_ch_matcher             = v.h_ch_matcher
      h_ch_path                = v.h_ch_path
      lb_algorithm             = v.lb_algorithm

    }
  }

  listener_tg_attachments_list = flatten([
    for v in local.rules_flattened : [
      for t_k, t_v in var.targets : {
        host             = t_k
        ip               = t_v
        port             = v.port
        listener_tg_name = v.tg_key
      }
    ]
  ])

  listener_tg_attachments = {
    for v in local.listener_tg_attachments_list : "${v.listener_tg_name}-${v.host}" => {
      ip               = v.ip
      port             = v.port
      listener_tg_name = v.listener_tg_name
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
  for_each = local.listener_tg

  vpc_id                        = var.vpc_id
  port                          = each.value.port
  protocol                      = each.value.proto
  protocol_version              = each.value.proto_v
  target_type                   = "ip"
  load_balancing_algorithm_type = each.value.lb_algorithm

  health_check {
    healthy_threshold   = each.value.h_ch_healthy_threshold
    unhealthy_threshold = each.value.h_ch_unhealthy_threshold
    interval            = each.value.h_ch_interval
    timeout             = each.value.h_ch_timeout
    protocol            = each.value.h_ch_protocol
    port                = each.value.h_ch_port
    matcher             = each.value.h_ch_matcher
    path                = each.value.h_ch_path
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = local.listener_tg_attachments

  target_group_arn = aws_lb_target_group.this[each.value.listener_tg_name].arn
  target_id        = each.value.ip
  port             = each.value.port
}

resource "aws_lb_listener" "this" {
  for_each = var.rules

  load_balancer_arn = aws_lb.this.arn
  port              = try(each.value.port, each.value.protocol == "HTTP" ? "80" : "443")
  protocol          = each.value.protocol

  # HTTPS specific values
  certificate_arn = each.value.protocol == "HTTPS" ? try(each.value.certificate_arn, null) : null
  ssl_policy      = try(each.value.ssl_policy, null)

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.listener_rules

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.tg_key].arn
  }

  dynamic "condition" {
    for_each = each.value.host_headers != null ? [1] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.http_headers != null ? [1] : []
    content {
      dynamic "http_header" {
        for_each = each.value.http_headers

        content {
          http_header_name = http_header.key
          values           = http_header.value
        }
      }
    }
  }


}
