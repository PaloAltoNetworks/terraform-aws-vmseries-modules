# PA VM AMI ID Lookup based on license type, region, version
data "aws_ami" "this" {
  count = var.vmseries_ami_id != null ? 0 : 1

  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.vmseries_version}*"]
  }
  filter {
    name   = "product-code"
    values = [var.vmseries_product_code]
  }

  name_regex = "^PA-VM-AWS-${var.vmseries_version}-[[:alnum:]]{8}-([[:alnum:]]{4}-){3}[[:alnum:]]{12}$"
}

data "aws_kms_alias" "ebs_kms" {
  name = var.ebs_kms_id
}

data "aws_caller_identity" "current" {}

locals {
  default_eni_subnet_names = flatten([for k, v in var.interfaces : v.subnet_id if v.device_index == 0])
  default_eni_sg_ids       = flatten([for k, v in var.interfaces : v.security_group_ids if v.device_index == 0])
  default_eni_public_ip    = flatten([for k, v in var.interfaces : v.create_public_ip if v.device_index == 0])
  account_id               = data.aws_caller_identity.current.account_id
  autoscaling_config = {
    ip_target_groups = var.ip_target_groups
  }
  delicense_config = {
    ssm_param = var.delicense_ssm_param_name
    enabled   = var.delicense_enabled
  }
  lambda_config = {
    region = var.region
  }
}

# Create launch template with a single interface
resource "aws_launch_template" "this" {
  name          = "${var.name_prefix}template"
  ebs_optimized = true
  image_id      = coalesce(var.vmseries_ami_id, try(data.aws_ami.this[0].id, null))
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  tags          = var.global_tags
  dynamic "iam_instance_profile" {
    for_each = var.vmseries_iam_instance_profile != "" ? [1] : []
    content {
      name = var.vmseries_iam_instance_profile
    }
  }

  update_default_version = var.launch_template_update_default_version
  user_data              = base64encode(var.bootstrap_options)

  network_interfaces {
    device_index                = 0
    security_groups             = [local.default_eni_sg_ids[0]]
    subnet_id                   = values(local.default_eni_subnet_names[0])[0]
    associate_public_ip_address = try(local.default_eni_public_ip[0])
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      kms_key_id            = data.aws_kms_alias.ebs_kms.arn
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}vmseries"
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# Create autoscaling group based on launch template and ALL subnets from var.interfaces
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}${var.asg_name}"
  vpc_zone_identifier = distinct([for k, v in local.default_eni_subnet_names[0] : v])
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  target_group_arns   = [var.target_group_arn]

  dynamic "tag" {
    for_each = var.global_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = var.launch_template_version
  }

  initial_lifecycle_hook {
    name                 = "${var.name_prefix}asg-launch-hook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = var.lifecycle_hook_timeout
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  initial_lifecycle_hook {
    name                 = "${var.name_prefix}asg-terminate-hook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = var.lifecycle_hook_timeout
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#instance_refresh
  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? { settings = var.instance_refresh } : {}
    content {
      strategy = instance_refresh.value.strategy
      preferences {
        checkpoint_delay             = instance_refresh.value.preferences.checkpoint_delay
        checkpoint_percentages       = instance_refresh.value.preferences.checkpoint_percentages
        instance_warmup              = instance_refresh.value.preferences.instance_warmup
        min_healthy_percentage       = instance_refresh.value.preferences.min_healthy_percentage
        skip_matching                = instance_refresh.value.preferences.skip_matching
        auto_rollback                = instance_refresh.value.preferences.auto_rollback
        scale_in_protected_instances = instance_refresh.value.preferences.scale_in_protected_instances
        standby_instances            = instance_refresh.value.preferences.standby_instances
      }
      triggers = instance_refresh.value.triggers
    }
  }

  timeouts {
    delete = var.delete_timeout
  }

  suspended_processes = var.suspended_processes

  lifecycle {
    precondition {
      condition     = var.instance_refresh != null ? (var.launch_template_version != "$Latest") : true
      error_message = "The instance refresh will not start when version = $Latest is configured in the launch_template block."
    }
  }

  depends_on = [
    aws_cloudwatch_event_target.instance_launch_event,
    aws_cloudwatch_event_target.instance_terminate_event
  ]
}

# Lookup information about the current AWS partition in which Terraform is working (e.g. `aws`, `aws-us-gov`, `aws-cn`)
data "aws_partition" "this" {}

# IAM role that will be used for Lambda function
resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}lambda_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach IAM policies to IAM role for Lambda
resource "aws_iam_role_policy" "lambda_iam_policy_default" {
  name   = "${var.name_prefix}lambda_iam_policy_default"
  role   = aws_iam_role.this.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:${data.aws_partition.this.partition}:logs:*:*:*"
        },
        {
            "Action": [
                "ec2:AllocateAddress",
                "ec2:AssociateAddress",
                "ec2:AttachNetworkInterface",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSubnets",
                "ec2:DeleteNetworkInterface",
                "ec2:DetachNetworkInterface",
                "ec2:DisassociateAddress",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:ReleaseAddress",
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DescribeAutoScalingGroups",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "kms:GenerateDataKey*",
            "kms:Decrypt",
            "kms:CreateGrant"
          ],
          "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_iam_policy_delicense" {
  count  = var.delicense_enabled ? 1 : 0
  name   = "${var.name_prefix}lambda_iam_policy_delicense"
  role   = aws_iam_role.this.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "ssm:GetParametersByPath",
                "ssm:GetParameter",
                "ssm:GetParameterHistory"
            ],
            "Resource": [
                "arn:${data.aws_partition.this.partition}:ssm:${var.region}:${local.account_id}:parameter/${var.delicense_ssm_param_name}"
            ]
        }
    ]
}
EOF
}

# Python external dependencies (e.g. panos libraries) are prepared according to document:
# https://docs.aws.amazon.com/lambda/latest/dg/python-package.html
resource "null_resource" "python_requirements" {
  triggers = {
    installed-pan-os-python = fileexists("${path.module}/scripts/pan_os_python-1.11.0.dist-info/METADATA") || var.lambda_execute_pip_install_once ? true : timestamp()
  }

  provisioner "local-exec" {
    command = "pip install --upgrade --target ${path.module}/scripts -r ${path.module}/scripts/requirements.txt"
  }
}

data "archive_file" "this" {
  type = "zip"

  source_dir  = "${path.module}/scripts"
  output_path = "${path.module}/lambda_payload.zip"

  depends_on = [
    null_resource.python_requirements
  ]
}

resource "aws_lambda_function" "this" {
  filename                       = data.archive_file.this.output_path
  function_name                  = "${var.name_prefix}asg_actions"
  role                           = aws_iam_role.this.arn
  handler                        = "lambda.lambda_handler"
  source_code_hash               = data.archive_file.this.output_base64sha256
  runtime                        = "python3.8"
  timeout                        = var.lambda_timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  tracing_config {
    mode = "Active"
  }
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
  environment {
    variables = {
      lambda_config      = jsonencode(local.lambda_config)
      interfaces_config  = jsonencode({ for k, v in var.interfaces : k => v if v.device_index != 0 })
      autoscaling_config = jsonencode(local.autoscaling_config)
      delicense_config   = jsonencode(local.delicense_config)
    }
  }
  tags = var.global_tags

  depends_on = [data.archive_file.this]
}

resource "aws_lambda_permission" "this" {
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.this.function_name
  principal           = "events.amazonaws.com"
  statement_id_prefix = var.name_prefix
}

resource "aws_cloudwatch_event_rule" "instance_launch_event_rule" {
  name          = "${var.name_prefix}asg_launch"
  tags          = var.global_tags
  event_pattern = <<EOF
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-launch Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${var.name_prefix}${var.asg_name}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "instance_terminate_event_rule" {
  name          = "${var.name_prefix}asg_terminate"
  tags          = var.global_tags
  event_pattern = <<EOF
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${var.name_prefix}${var.asg_name}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "instance_launch_event" {
  rule      = aws_cloudwatch_event_rule.instance_launch_event_rule.name
  target_id = "${var.name_prefix}asg_launch"
  arn       = aws_lambda_function.this.arn
}

resource "aws_cloudwatch_event_target" "instance_terminate_event" {
  rule      = aws_cloudwatch_event_rule.instance_terminate_event_rule.name
  target_id = "${var.name_prefix}asg_terminate"
  arn       = aws_lambda_function.this.arn
}

resource "aws_autoscalingplans_scaling_plan" "this" {
  count = var.scaling_plan_enabled ? 1 : 0
  name  = "${var.name_prefix}scaling-plan"
  application_source {
    dynamic "tag_filter" {
      for_each = var.scaling_tags
      content {
        key    = tag_filter.key
        values = [tag_filter.value]
      }
    }
  }
  scaling_instruction {
    max_capacity       = var.max_size
    min_capacity       = var.min_size
    resource_id        = format("autoScalingGroup/%s", aws_autoscaling_group.this.name)
    scalable_dimension = "autoscaling:autoScalingGroup:DesiredCapacity"
    service_namespace  = "autoscaling"
    target_tracking_configuration {
      customized_scaling_metric_specification {
        metric_name = var.scaling_metric_name
        namespace   = var.scaling_cloudwatch_namespace
        statistic   = var.scaling_statistic
      }
      target_value = var.scaling_target_value
    }
  }
}
