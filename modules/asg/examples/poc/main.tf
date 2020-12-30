module "vpc" {
  source           = "../../../vpc"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpcs
  vpc_route_tables = var.route_tables
  subnets          = var.vpc_subnets
  # nat_gateways     = var.nat_gateways
  # vpc_endpoints    = var.vpc_endpoints
  security_groups = var.security_groups
}


# Product code map based on license type for ami filter
variable "fw_license_type_map" {
  type = map(string)
  default = {
    "byol"  = "6njl1pau431dv1qxipg63mvah"
    "payg1" = "6kxdw3bbmdeda3o6i1ggqt4km"
    "payg2" = "806j2of0qy5osgjjixq9gqc6g"
  }
}


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


resource "aws_launch_template" "this" {
  name          = "${var.prefix_name_tag}template1"
  ebs_optimized = true
  image_id      = data.aws_ami.pa-vm.id
  instance_type = var.fw_instance_type
  key_name      = var.ssh_key_name
  # vpc_security_group_ids = values(module.vpc.security_group_ids) # Causing "Error: Error creating AutoScaling Group: InvalidQueryParameter: Invalid launch template: When a network interface is provided, the security groups must be a part of it."

  dynamic network_interfaces {
    for_each = var.interfaces
    content {
      device_index    = network_interfaces.value.index
      subnet_id       = module.vpc.subnet_ids[network_interfaces.value.subnet_name]
      security_groups = [module.vpc.security_group_ids[network_interfaces.value.security_group]]
      # This one doesn't work as expected, because attach single subnet (chosen RANDOMLY) to all interfaces

    }
  }

  user_data = base64encode(join(",", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  ))))

}


resource "aws_autoscaling_group" "this" {
  availability_zones = distinct([for k, v in var.vpc_subnets : v.az])
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}
