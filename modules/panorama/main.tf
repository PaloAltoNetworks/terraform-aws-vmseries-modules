# Panorama AMI ID lookup based on license type, region, version
data "aws_ami" "this" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Panorama-AWS-${var.panorama_version}*"]
  }
  filter {
    name   = "product-code"
    values = [var.product_code]
  }

  name_regex = "^Panorama-AWS-${var.panorama_version}-[[:alnum:]]{8}-([[:alnum:]]{4}-){3}[[:alnum:]]{12}$"
}

# Retrieve the default KMS key in the current region for EBS encryption
data "aws_ebs_default_kms_key" "current" {
  count = var.ebs_encrypted ? 1 : 0
}

# Create the Panorama Instance
resource "aws_instance" "this" {
  ami                                  = data.aws_ami.this.id
  instance_type                        = var.instance_type
  availability_zone                    = var.availability_zone
  key_name                             = var.ssh_key_name
  private_ip                           = var.private_ip_address
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = var.vpc_security_group_ids
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  monitoring                           = false
  iam_instance_profile                 = var.panorama_iam_role

  root_block_device {
    delete_on_termination = true
    encrypted             = var.ebs_encrypted
    kms_key_id            = var.ebs_encrypted == false ? null : data.aws_kms_alias.current_arn[0].target_key_arn
  }

  tags = merge(var.global_tags, { Name = var.name })
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# Create Elastic IP
resource "aws_eip" "this" {
  count = var.create_public_ip ? 1 : 0

  instance = aws_instance.this.id
  vpc      = true

  tags = merge(var.global_tags, { Name = var.name })
}

resource "aws_ebs_volume" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  availability_zone = var.availability_zone
  size              = try(each.value.ebs_size, "2000")
  encrypted         = try(each.value.ebs_encrypted, false)
  kms_key_id        = try(var.ebs_kms_key_alias, null)

  tags = merge(var.global_tags, { Name = try(each.value.name, var.name) })
}

resource "aws_volume_attachment" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  device_name  = each.value.ebs_device_name
  instance_id  = aws_instance.this.id
  volume_id    = aws_ebs_volume.this[each.key].id
  force_detach = try(each.value.force_detach, false)
  skip_destroy = try(each.value.skip_destroy, false)
}
