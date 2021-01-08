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
  source            = "../../../asg"
  ssh_key_name      = var.ssh_key_name
  name_prefix       = var.prefix_name_tag
  bootstrap_options = var.bootstrap_options
  subnet_ids        = module.vpc.subnet_ids
  interfaces        = var.interfaces
  global_tags       = var.global_tags
}

resource "aws_autoscaling_policy" "bat" {
  name                   = "${var.prefix_name_tag}asg-policy"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = module.asg.asg.name
}

output "asg" { value = module.asg.asg }