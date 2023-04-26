locals {
  # The list below is used to de-nest the listener rules properties. 
  # For each application definition you have target group and health check configuration 
  # and one or more listener rules properties.
  # In each element of this list you will have listener rule properties combined with 
  # parent application's target group and health check properties.
  # This flat list is then used to create maps for target group, target group attachment and 
  # listener rules configuration.
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
        lb_algorithm             = try(l_v.round_robin, null) != null ? (l_v.round_robin ? "round_robin" : "least_outstanding_requests") : "round_robin"
        host_headers             = try(l_v.host_headers, null)
        priority                 = l_k
        http_headers             = try(l_v.http_headers, null)
        http_request_method      = try(l_v.http_request_method, null)
        path_pattern             = try(l_v.path_pattern, null)
        query_strings            = try(l_v.query_strings, null)
        source_ip                = try(l_v.source_ip, null)
      }
    ]
  ])

  # A map of target groups that will be referenced in listener rules.
  # To minimize a number of target groups we create unique groups
  # per application and listener rule's port, hence the intermediary step of creating `listener_tg_unique`.
  # Example, if a listener for an application has 3 listener rules using
  # the same 8080 port, only one target group will be created.
  # The condition is that if you specify the same target port in several rules
  # other target group properties (like protocol, load balancing algorithm, etc) also have to be the same.
  # If they aren't, terraform will error out while trying to create a unique list.
  # The map below contains also health check properties specific for particular application.
  listener_tg_unique = distinct([
    for v in local.rules_flattened : {
      tg_key                   = v.tg_key
      app_name                 = v.app_name
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
  ])
  listener_tg = {
    for v in local.listener_tg_unique : v.tg_key => {
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

  # Listener rules map. Contains only listener rules properties and a reference a target group.
  listener_rules = {
    for v in local.rules_flattened : "${v.app_name}-${v.priority}" => {
      listener_key        = v.app_name
      priority            = v.priority
      tg_key              = v.tg_key
      host_headers        = v.host_headers
      http_headers        = v.http_headers
      http_request_method = v.http_request_method
      path_pattern        = v.path_pattern
      query_strings       = v.query_strings
      source_ip           = v.source_ip
    }
  }

  # A flat list that is a combination of target group properties and information
  # on firewalls' IPs.
  # This will be used to create a map of target groups attachments.
  # One of the properties is the target group reference.
  listener_tg_attachments_list = flatten([
    for v in local.listener_tg_unique : [
      for t_k, t_v in var.targets : {
        host             = t_k
        ip               = t_v
        port             = v.port
        listener_tg_name = v.tg_key
      }
    ]
  ])

  # A map of target group attachments.
  listener_tg_attachments = {
    for v in local.listener_tg_attachments_list : "${v.listener_tg_name}-${v.host}" => {
      ip               = v.ip
      port             = v.port
      listener_tg_name = v.listener_tg_name
    }
  }
}

# ## Access Logs Bucket ##
# For Application Load Balancers where access logs are stored in S3 Bucket.
data "aws_s3_bucket" "this" {
  count = var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket = var.access_logs_s3_bucket_name
}

resource "aws_s3_bucket" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket        = var.access_logs_s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  acl    = "private"
}

data "aws_elb_service_account" "this" {}

data "aws_iam_policy_document" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${aws_s3_bucket.this[0].id}/${var.access_logs_s3_bucket_prefix != null ? "${var.access_logs_s3_bucket_prefix}/" : ""}AWSLogs/*"]
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}
# ######################## #

## Add communication to ALB with ephemeral port

resource "aws_security_group_rule" "alb_att" {

  from_port                = 0
  protocol                 = "all"
  source_security_group_id = var.security_groups[0]
  security_group_id        = var.security_groups[0]
  to_port                  = 0
  type                     = "ingress"
}

# ## Application Load Balancer ##
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
# ######################## #

# ## Target Group Configuration ##
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

  target_group_arn  = aws_lb_target_group.this[each.value.listener_tg_name].arn
  target_id         = each.value.ip
  port              = each.value.porta
  availability_zone = var.target_group_az
}
# ######################## #

# ## Listener Configuration ##
resource "aws_lb_listener" "this" {
  for_each = var.rules

  load_balancer_arn = aws_lb.this.arn
  port              = try(each.value.port, each.value.protocol == "HTTP" ? "80" : "443")
  protocol          = each.value.protocol

  # HTTPS specific values
  certificate_arn = each.value.protocol == "HTTPS" ? try(each.value.certificate_arn, null) : null
  ssl_policy      = try(each.value.ssl_policy, null)

  # catch-all rule, if no listener rule matches
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "503"
    }
  }

  tags = merge({ name : each.key }, var.tags)
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.listener_rules

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

  # we only forward traffic to Firewalls
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.tg_key].arn
  }

  # a block for host_header condition
  dynamic "condition" {
    for_each = each.value.host_headers != null ? [1] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  # a block of http_header conditions
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

  # a block for http_request_method condition
  dynamic "condition" {
    for_each = each.value.http_request_method != null ? [1] : []

    content {
      http_request_method {
        values = each.value.http_request_method
      }
    }
  }

  # a block for path_pattern condition
  dynamic "condition" {
    for_each = each.value.path_pattern != null ? [1] : []

    content {
      path_pattern {
        values = each.value.path_pattern
      }
    }
  }

  # a block of query_string conditions
  dynamic "condition" {
    for_each = each.value.query_strings != null ? [1] : []
    content {
      dynamic "query_string" {
        for_each = each.value.query_strings

        content {
          key   = length(regexall("^nokey_.*$", query_string.key)) > 0 ? null : query_string.key
          value = query_string.value
        }
      }
    }
  }

  # a block for source_ip condition
  dynamic "condition" {
    for_each = each.value.source_ip != null ? [1] : []

    content {
      source_ip {
        values = each.value.source_ip
      }
    }
  }
}
# ######################## #
