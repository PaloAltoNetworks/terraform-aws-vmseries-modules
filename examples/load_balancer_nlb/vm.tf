data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_network_interface" "web1" {
  subnet_id       = module.vpc.subnet_ids["private-1a"]
  tags            = merge({ "Name" = format("%s-web1", var.prefix_name_tag) }, var.global_tags)
  security_groups = [module.vpc.security_group_ids["sg1"]]
}

resource "aws_instance" "web1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags          = merge({ "Name" = format("%s-web1", var.prefix_name_tag) }, var.global_tags)
  key_name      = "kbechler"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web1.id
  }
}

resource "aws_network_interface" "web2" {
  subnet_id       = module.vpc.subnet_ids["private-1b"]
  tags            = merge({ "Name" = format("%s-web2", var.prefix_name_tag) }, var.global_tags)
  security_groups = [module.vpc.security_group_ids["sg1"]]
}

resource "aws_instance" "web2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags          = merge({ "Name" = format("%s-web2", var.prefix_name_tag) }, var.global_tags)
  key_name      = "kbechler"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web2.id
  }
}

