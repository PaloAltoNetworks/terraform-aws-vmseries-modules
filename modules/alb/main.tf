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
        port     = try(v.target_port, v.port)
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
    for_each = var.configure_access_logs ? { 1 = 1 } : {}

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

# resource "aws_lb_target_group" "this" {
#   for_each = var.balance_rules

#   name        = "${var.lb_name}-tg-${each.key}"
#   vpc_id      = var.vpc_id
#   port        = try(each.value.target_port, each.value.port)
#   protocol    = each.value.protocol
#   target_type = each.value.target_type


#   health_check {
#     healthy_threshold   = try(each.value.threshold, null)
#     unhealthy_threshold = try(each.value.threshold, null)
#     interval            = try(each.value.interval, null)
#     protocol            = "TCP"
#     port                = try(each.value.health_check_port, "traffic-port")
#   }

#   dynamic "stickiness" {
#     # For TLS stickiness is not supported, see link:
#     # https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#sticky-sessions#:~:text=Sticky%20sessions%20are%20not%20supported%20with%20TLS%20listeners%20and%20TLS%20target%20groups.
#     for_each = each.value.stickiness && each.value.protocol != "TLS" ? [1] : []

#     content {
#       enabled = true
#       type    = "source_ip"
#     }
#   }

#   tags = var.tags
# }

# resource "aws_lb_target_group_attachment" "this" {
#   for_each = local.target_attachments

#   target_group_arn = aws_lb_target_group.this[each.value.app_name].arn
#   target_id        = each.value.id
#   port             = each.value.port
# }

# resource "aws_lb_listener" "this" {
#   for_each = var.balance_rules

#   load_balancer_arn = aws_lb.this.arn
#   port              = each.value.port
#   protocol          = each.value.protocol

#   # TLS specific values
#   certificate_arn = each.value.protocol == "TLS" ? try(each.value.certificate_arn, null) : null
#   alpn_policy     = each.value.protocol == "TLS" ? try(each.value.alpn_policy, "None") : null

#   # This is meant to be a typical Layer4 LB, so the only supported action is `forward`.
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.this[each.key].arn
#   }

#   tags = var.tags
# }

# # Private Load Balancer's IP addresses. It can be handy to have them in module's output, especially that they can be used
# # for Mangement Profile configuration - to limit health check probe traffic to LB's internal IPs only.
# data "aws_network_interface" "this" {
#   for_each = var.subnets

#   filter {
#     name   = "description"
#     values = ["ELB ${aws_lb.this.arn_suffix}"]
#   }

#   filter {
#     name   = "subnet-id"
#     values = [each.value.id]
#   }
# }
