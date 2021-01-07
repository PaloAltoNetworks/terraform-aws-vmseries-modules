#### PA VM AMI ID Lookup based on license type, region, version ####
data "aws_ami" "pa-vm" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = [var.fw_license_type_map[var.fw_license_type]]
  }

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.fw_version}*"]
  }
}


# Create launch template with a single interface
resource "aws_launch_template" "this" {
  name          = "${var.name_prefix}template1"
  ebs_optimized = true
  image_id      = data.aws_ami.pa-vm.id
  instance_type = var.fw_instance_type
  key_name      = var.ssh_key_name

  network_interfaces {
    device_index = 0
    subnet_id    = var.subnet_ids[var.interfaces.0.subnet_name]
    # security_groups = [var.interfaces.0.security_group]
  }

  user_data = base64encode(join(",", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  ))))

}

# Create autoscaling group based on launch template and ALL subnets from var.interfaces
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}asg1"
  vpc_zone_identifier = distinct([for k, v in var.interfaces : var.subnet_ids[v.subnet_name]])
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

# Add lifecycle hook to autoscaling group
resource "aws_autoscaling_lifecycle_hook" "this" {
  name                   = "${var.name_prefix}hook1"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = var.lifecycle_hook_timeout
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
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
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DetachNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:DescribeSubnets",
                "ec2:AttachNetworkInterface",
                "ec2:DescribeInstances",
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



resource "aws_lambda_function" "this" {
  filename         = "lambda_payload.zip"
  function_name    = "${var.name_prefix}add_nics"
  role             = aws_iam_role.this.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = filebase64sha256("lambda_payload.zip")
  runtime          = "python3.8"
}


resource "aws_cloudwatch_event_rule" "this" {
  name          = "${var.name_prefix}add_nics"
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
      "${aws_autoscaling_group.this.name}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "${var.name_prefix}add_nics"
  arn       = aws_lambda_function.this.arn
}