## VPC

module "security_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}-vpc"
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "security_subnet_sets" {
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

locals {
  security_vpc_routes = concat(
    [for cidr in ["app_vm", "app_lb"] :
      {
        subnet_key   = cidr
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = "0.0.0.0/0"
      }
    ]
  )
}
module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

## ALB

module "public_alb" {
  source = "../../modules/alb"

  lb_name         = replace("${var.name_prefix}${var.application_lb_name}", "_", "-")
  subnets         = { for k, v in module.security_subnet_sets["app_vm"].subnets : k => { id = v.id } }
  vpc_id          = module.security_vpc.id
  security_groups = [module.security_vpc.security_group_ids["app_vm"]]
  rules           = var.application_lb_rules
  targets         = { for k, v in var.app_vms : k => aws_instance.app_vm[k].private_ip }

  tags = var.global_tags
}


### app EC2 instance ###

data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.21*-linux-debian-10-x86_64-hvm-ebs-nami"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  owners = ["979382823631"] # bitnami = 979382823631
}

resource "tls_private_key" "random_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "random_ssh_key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.random_ssh_key.public_key_openssh
}

data "aws_ebs_default_kms_key" "current" {
}

data "aws_kms_alias" "current_arn" {
  name = data.aws_ebs_default_kms_key.current.key_arn
}

resource "aws_instance" "app_vm" {
  for_each = var.app_vms

  ami                         = data.aws_ami.this.id
  instance_type               = var.app_vm_type
  key_name                    = aws_key_pair.random_ssh_key_pair.key_name
  subnet_id                   = module.security_subnet_sets["app_vm"].subnets[each.value.az].id
  vpc_security_group_ids      = [module.security_vpc.security_group_ids["app_vm"]]
  tags                        = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
  associate_public_ip_address = true
  ebs_optimized               = true
  iam_instance_profile        = var.app_vm_iam_instance_profile

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_alias.current_arn.target_key_arn
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

data "aws_network_interface" "bar" {
  for_each = var.app_vms
  id       = aws_instance.app_vm[each.key].primary_network_interface_id
}