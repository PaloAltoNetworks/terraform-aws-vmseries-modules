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

locals {
  default_eni_subnet_names = flatten([for k, v in var.interfaces : v.subnet_id if v.device_index == 0])
  default_eni_sg_ids       = flatten([for k, v in var.interfaces : v.security_group_ids if v.device_index == 0])
  default_eni_public_ip    = flatten([for k, v in var.interfaces : v.create_public_ip if v.device_index == 0])
}

# Create launch template with a single interface
resource "aws_launch_template" "this" {
  name          = "${var.name_prefix}template"
  ebs_optimized = true
  image_id      = coalesce(var.vmseries_ami_id, try(data.aws_ami.this[0].id, null))
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  tags          = var.global_tags

  user_data = base64encode(join("\n", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  ))))

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
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}vmseries"
    }
  }
}

# Create autoscaling group based on launch template and ALL subnets from var.interfaces
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}${var.asg_name}"
  vpc_zone_identifier = distinct([for k, v in local.default_eni_subnet_names[0] : v])
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

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
    version = "$Latest"
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

  #  depends_on = [
  #    aws_cloudwatch_event_target.instance_launch_event,
  #    aws_cloudwatch_event_target.instance_terminate_event
  #  ]

}

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

# Attach IAM Policy to IAM role for Lambda
resource "aws_iam_role_policy" "this" {
  name   = "${var.name_prefix}lambda_iam_policy"
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
            "Resource": "arn:aws:logs:*:*:*"
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
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

data "archive_file" "this" {
  type = "zip"

  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_payload.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = "${var.name_prefix}asg_actions"
  role             = aws_iam_role.this.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.this.output_base64sha256
  runtime          = "python3.8"
  timeout          = var.lambda_timeout
  environment {
    variables = {
      lambda_config = jsonencode({ for k, v in var.interfaces : k => v if v.device_index != 0 })
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
