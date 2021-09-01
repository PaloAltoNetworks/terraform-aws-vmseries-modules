data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

module "app1_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"

  name           = "app1"
  instance_count = 1

  ami                    = data.aws_ami.this.id
  instance_type          = "t2.micro"
  key_name               = local.ssh_key_name
  vpc_security_group_ids = [module.app1_vpc.security_group_ids["app1_vm"]]
  subnet_id              = module.app1_subnet_sets["app1_vm"].subnets[local.app1_az].id
  tags                   = var.global_tags
}

locals {
  # Just use a single virtual machine in a single AZ as a test box.
  app1_az = "${var.region}a"
}

resource "aws_eip" "lb" {
  vpc = true
}

# The Load Balancer.
# It is not for balancing the load per se, but rather as a route separation tool (as it introduces extra route tables).
module "app1_lb" {
  source = "terraform-aws-modules/alb/aws"
  # The name "alb" is a bit misleading as the module can deploy either ALB or NLB.
  # It means it can create a load balancer of type "application" (ALB) or "network" (NLB).
  version = "~> 6.5"

  name               = "lb1"
  load_balancer_type = "network"
  vpc_id             = module.app1_subnet_sets["app1_lb"].vpc_id
  subnet_mapping = [
    {
      allocation_id = aws_eip.lb.id
      subnet_id     = module.app1_subnet_sets["app1_lb"].subnets[local.app1_az].id
    }
  ]

  http_tcp_listeners = [
    {
      port               = 22
      protocol           = "TCP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name_prefix          = "tg0"
      backend_protocol     = "TCP"
      backend_port         = 22
      target_type          = "instance"
      deregistration_delay = 10
      targets = {
        my_ec2 = {
          target_id = try(module.app1_ec2.id[0], null)
          port      = 22
        }
      }
    }
  ]

  tags = var.global_tags

  depends_on = [
    # Workaround for error: VPC vpc-0123 has no internet gateway.
    module.app1_vpc
  ]
}

output "app1_inspected_dns_name" {
  value = module.app1_lb.lb_dns_name
}

output "app1_inspected_public_ip" {
  value = aws_eip.lb.public_ip
}
