data "archive_file" "this" {
  type        = "zip"
  source_file = "../../../asg/lambda.py"
  output_path = "lambda_payload.zip"
}

module "vpc" {
  source           = "../../../vpc"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpcs
  vpc_route_tables = var.route_tables
  subnets          = var.vpc_subnets
  security_groups  = var.security_groups
}

module "asg" {
  source             = "../../../asg"
  ssh_key_name       = var.ssh_key_name
  name_prefix        = var.prefix_name_tag
  bootstrap_options  = var.bootstrap_options
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = module.vpc.security_group_ids
  interfaces         = var.interfaces
  global_tags        = var.global_tags
  max_size           = 0
  min_size           = 0
  desired_capacity   = 0
}

resource "aws_autoscaling_policy" "up" {
  name                   = "${var.prefix_name_tag}asg-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = module.asg.asg.name
}

resource "aws_autoscaling_policy" "down" {
  name                   = "${var.prefix_name_tag}asg-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = module.asg.asg.name
}


resource "aws_cloudwatch_metric_alarm" "up" {
  alarm_name          = "${var.prefix_name_tag}alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "panSessionThroughputKbps"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_actions       = [aws_autoscaling_policy.up.arn]
  dimensions          = { AutoScalingGroupName = module.asg.asg.name }
}

resource "aws_cloudwatch_metric_alarm" "down" {
  alarm_name          = "${var.prefix_name_tag}alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "panSessionThroughputKbps"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  alarm_actions       = [aws_autoscaling_policy.down.arn]
  dimensions          = { AutoScalingGroupName = module.asg.asg.name }
}



output "asg" { value = module.asg.asg }

