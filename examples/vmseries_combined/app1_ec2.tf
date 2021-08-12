data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
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
  monitoring             = true
  vpc_security_group_ids = [module.app1_vpc.security_group_ids["app1_web"]]
  subnet_id              = module.app1_subnet_sets["app1_web"].subnets["eu-west-3a"].id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eip" "this" {
  vpc      = true
  instance = module.app1_ec2.id[0]
}

output "app1_inspected_public_ip" {
  value = aws_eip.this.public_ip
}
