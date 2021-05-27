#########################################################
#                     NLBs                              #
#########################################################


################
# Local loops to build maps for NLB related resources
################

locals {
  eips = flatten([
    for nlb_key, nlb in var.nlbs : [
      for subnet_key, subnet in var.elb_subnet_ids : {
        nlb_key    = nlb_key
        nlb_name   = nlb.name
        subnet_key = subnet_key
        subnet_id  = subnet
      }
    ]
    if lookup(nlb, "eips", null) == true
  ])

  eips_map = {
    for subnet in local.eips : "${subnet.nlb_key}-${subnet.subnet_key}" => subnet
  }

  nlb_apps = flatten([
    for nlb_key, nlb in var.nlbs : [
      for app_key, app in nlb.apps : {
        nlb_key       = nlb_key
        app_key       = app_key
        app_name      = app.name
        protocol      = app.protocol
        listener_port = app.listener_port
        target_port   = app.target_port
        targets       = var.target_instance_ids
      }
    ]
  ])

  nlb_apps_map = {
    for app in local.nlb_apps : "${app.nlb_key}-${app.app_key}" => app
  }

  nlb_targets = flatten([
    for nlb_app_key, nlb_app in local.nlb_apps_map : [
      for target_key, target_id in var.target_instance_ids : {
        nlb_key     = nlb_app.nlb_key
        nlb_app_key = nlb_app_key
        target_key  = target_key
        target_id   = target_id
      }
    ]
  ])

  nlb_targets_map = {
    for target in local.nlb_targets : "${target.nlb_app_key}-${target.target_key}" => target
  }
}


################
# NLB Resources
################

resource "aws_eip" "nlb" {
  for_each = local.eips_map
  vpc      = true
  tags     = merge({ "Name" = each.value.nlb_name }, var.global_tags)
}


resource "aws_lb" "nlb" {
  for_each = var.nlbs
  # for_each                         = {
  #   for key, nlb in var.nlbs : "${subnet.nlb_key}-${subnet.subnet_key}" => subnet.subnet_id
  # }
  name                             = each.value.name
  internal                         = lookup(each.value, "internal", null)
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = lookup(each.value, "enable_cross_zone_load_balancing", null)
  tags                             = var.global_tags

  dynamic "subnet_mapping" {
    for_each = var.elb_subnet_ids
    content {
      subnet_id     = subnet_mapping.value
      allocation_id = lookup(each.value, "eips", null) == true ? aws_eip.nlb["${each.key}-${subnet_mapping.key}"].id : null
    }
  }
}

resource "aws_lb_target_group" "nlb" {
  for_each = local.nlb_apps_map
  # name = "${each.value.lb_key}-${each.value.front_end_port}"
  # Issue here with AWS provider and trying to modify target groups in-use by listeners. Workaround Using name_prefix instead
  # https://github.com/terraform-providers/terraform-provider-aws/issues/636
  name_prefix = "nlbapp"
  port        = each.value.target_port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({ "Name" = each.value.app_name }, var.global_tags)
}

resource "aws_lb_listener" "nlb" {
  for_each = local.nlb_apps_map
 
  load_balancer_arn = aws_lb.nlb[each.value.nlb_key].arn
  port              = each.value.listener_port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb[each.key].arn
  }
  depends_on = [aws_lb_target_group.nlb]
}

resource "aws_lb_target_group_attachment" "nlb" {
  for_each         = local.nlb_targets_map
  target_group_arn = aws_lb_target_group.nlb[each.value.nlb_app_key].arn
  target_id        = each.value.target_id
}


#########################################################
#                     ALBs                              #
#########################################################


################
# Local loops to build maps for ALB related resources
################

locals {
  alb_apps = flatten([
    for alb_key, alb in var.albs : [
      for app_key, app in alb.apps : {
        alb_key           = alb_key
        app_key           = app_key
        app_name          = app.name
        listener_protocol = app.listener_protocol
        target_protocol   = app.target_protocol
        target_port       = app.target_port
        rule_type         = app.rule_type
        rule_patterns     = app.rule_patterns
        targets           = var.target_instance_ids
      }
    ]
  ])

  alb_apps_map = {
    for app in local.alb_apps : "${app.alb_key}-${app.app_key}" => app
  }

  alb_targets = flatten([
    for app_key, alb_app in local.alb_apps_map : [
      for target_key, target_id in var.target_instance_ids : {
        alb_key    = alb_app.alb_key
        app_key    = app_key
        target_key = target_key
        target_id  = target_id
      }
    ]
  ])

  alb_targets_map = {
    for target in local.alb_targets : "${target.app_key}-${target.target_key}" => target
  }

  alb_https_certs = flatten([
    for alb_key, alb in var.albs : [
      for cert_key, cert_arn in alb.additional_certificate_arns : {
        alb_key  = alb_key
        cert_key = cert_key
        cert_arn = cert_arn
      }
    ]
    if contains(keys(alb), "additional_certificate_arns")
  ])

  alb_https_certs_map = {
    for cert in local.alb_https_certs : "${cert.alb_key}-${cert.cert_key}" => cert
  }
}


################
# ALB Resources
################


resource "aws_lb" "alb" {
  for_each           = var.albs
  name               = each.value.name
  internal           = lookup(each.value, "internal", null)
  load_balancer_type = "application"
  subnets            = var.elb_subnet_ids
  security_groups    = lookup(each.value, "security_groups", null)
  tags               = merge({ "Name" = each.value.name }, var.global_tags)
}

resource "aws_lb_target_group" "alb" {
  for_each = local.alb_apps_map
  # name = "${each.value.lb_key}-${each.value.front_end_port}"
  # Issue here with AWS provider and trying to modify target groups in-use by listeners. Using name_prefix instead
  # https://github.com/terraform-providers/terraform-provider-aws/issues/636
  name_prefix = "albapp"
  port        = each.value.target_port
  protocol    = each.value.target_protocol
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = each.value.app_name }, var.global_tags)

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_target_group_attachment" "alb" {
  for_each         = local.alb_targets_map
  target_group_arn = aws_lb_target_group.alb[each.value.app_key].arn
  target_id        = each.value.target_id
}



# HTTPS listener with default fixed response
resource "aws_lb_listener" "alb_https" {
  for_each = { for alb_key, alb in var.albs : alb_key => alb
  if lookup(alb, "https_listener", null) == true }
  load_balancer_arn = aws_lb.alb[each.key].arn
  port              = each.value.https_listener_port
  certificate_arn   = each.value.default_certificate_arn
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No Rule Matched"
      status_code  = "200"
    }
  }
}

# Optionally add additional certs to HTTPS listener
resource "aws_lb_listener_certificate" "this" {
  for_each        = local.alb_https_certs_map
  listener_arn    = aws_lb_listener.alb_https[each.value.alb_key].arn
  certificate_arn = each.value.cert_arn
}


# HTTP listener with default fixed response
resource "aws_lb_listener" "alb_http" {
  for_each = { for alb_key, alb in var.albs : alb_key => alb
  if lookup(alb, "http_listener", null) == true }
  load_balancer_arn = aws_lb.alb[each.key].arn
  port              = each.value.http_listener_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No Rule Matched"
      status_code  = "200"
    }
  }
}


# Create listener rule for each defined ALB HTTP app
resource "aws_lb_listener_rule" "alb_http" {
  for_each = { for app_key, alb_app in local.alb_apps_map : app_key => alb_app
  if lookup(alb_app, "listener_protocol", null) == "HTTP" }
  listener_arn = aws_lb_listener.alb_http[each.value.alb_key].arn
  priority     = each.value.target_port #Reuse target port value to ensure a unique priority value

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb["${each.value.alb_key}-${each.value.app_key}"].arn
  }

  dynamic "condition" {
    for_each = each.value.rule_type == "path" ? [each.value.rule_patterns] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.rule_type == "host_header" ? [each.value.rule_patterns] : []
    content {
      host_header {
        values = condition.value
      }
    }
  }
}


# Create listener rule for each defined ALB HTTP app
resource "aws_lb_listener_rule" "alb_https" {
  for_each = { for app_key, alb_app in local.alb_apps_map : app_key => alb_app
  if lookup(alb_app, "listener_protocol", null) == "HTTPS" }
  listener_arn = aws_lb_listener.alb_https[each.value.alb_key].arn
  priority     = each.value.target_port #Reuse target port value to ensure a unique priority value

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb["${each.value.alb_key}-${each.value.app_key}"].arn
  }

  dynamic "condition" {
    for_each = each.value.rule_type == "path" ? [each.value.rule_patterns] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.rule_type == "host_header" ? [each.value.rule_patterns] : []
    content {
      host_header {
        values = condition.value
      }
    }
  }
}
