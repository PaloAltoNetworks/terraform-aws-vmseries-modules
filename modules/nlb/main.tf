locals {
  # Boolean that agregates initial conditions on the type of the Load Balancer that will be created.
  # It is used later in several places related to the way me map the Load Balancer to the subnets.
  public_lb_with_eip = var.create_dedicated_eips && !var.internal_lb

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
        target_az = try(v.target_az, null)
      }
    ]
  ])

  target_attachments = {
    for v in local.fw_instance_list :
    "${v.app_name}-${v.name}" => {
      app_name = v.app_name
      id       = v.id
      port     = v.port
      target_az = v.target_az
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

resource "aws_s3_bucket_versioning" "this" {
  count  = !var.access_logs_byob && var.configure_access_logs ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = !var.access_logs_byob && var.configure_access_logs ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = !var.access_logs_byob && var.configure_access_logs ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

resource "aws_eip" "this" {
  for_each = local.public_lb_with_eip ? var.subnets : {}

  tags = merge({ Name = "${var.name}-${each.key}" }, var.tags)
}

resource "aws_lb" "this" {
  name                             = var.name
  internal                         = var.internal_lb
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # If we relay on AWS to manage public IPs we use `subnets` to attach a Load Balancer with a subnet.
  # We use `subnets` property also for non-public LBs.
  # On the contrary, if we would like to have a public Load Balancer with our own EIPs
  # we need to assign them to a subnet explicitly, therefore we use `subnet mapping`.
  # The code below does the proper use of `subnets` and `subnet_mapping`
  # based on the use cases described above.
  #
  # Generally, the decision is being made on a fact if we have a public Load Balancer
  # with dedicated EIPs or not.
  subnets = local.public_lb_with_eip ? null : [for k, v in var.subnets : v.id]
  dynamic "subnet_mapping" {
    for_each = local.public_lb_with_eip ? var.subnets : {}

    content {
      subnet_id     = subnet_mapping.value.id
      allocation_id = aws_eip.this[subnet_mapping.key].id
    }
  }

  dynamic "access_logs" {
    for_each = var.configure_access_logs ? [1] : []

    content {
      bucket  = var.access_logs_byob ? data.aws_s3_bucket.this[0].id : aws_s3_bucket.this[0].id
      prefix  = var.access_logs_s3_bucket_prefix
      enabled = true
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.balance_rules

  name        = "${var.name}-${each.key}"
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
    # For TLS stickiness is not supported, see link:
    # https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#sticky-sessions#:~:text=Sticky%20sessions%20are%20not%20supported%20with%20TLS%20listeners%20and%20TLS%20target%20groups.
    for_each = each.value.stickiness && each.value.protocol != "TLS" ? [1] : []

    content {
      enabled = true
      type    = "source_ip"
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = local.target_attachments

  target_group_arn = aws_lb_target_group.this[each.value.app_name].arn
  target_id        = each.value.id
  port             = each.value.port
  availability_zone = each.value.target_az
}

resource "aws_lb_listener" "this" {
  for_each = var.balance_rules

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  # TLS specific values
  certificate_arn = each.value.protocol == "TLS" ? try(each.value.certificate_arn, null) : null
  alpn_policy     = each.value.protocol == "TLS" ? try(each.value.alpn_policy, "None") : null

  # This is meant to be a typical Layer4 LB, so the only supported action is `forward`.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = var.tags
}
