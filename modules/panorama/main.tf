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

  root_block_device {
    delete_on_termination = true
  }

  tags = merge(var.global_tags, { Name = var.name })
}

# Create Elastic IP
resource "aws_eip" "this" {
  count = var.create_public_ip ? 1 : 0

  instance = aws_instance.this.id
  vpc      = true

  tags = merge(var.global_tags, { Name = "${var.name}-eip" })
}

# Get the default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

resource "aws_ebs_volume" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  availability_zone = try(each.value.availability_zone, var.availability_zone)
  size              = try(each.value.ebs_size, "2000")
  encrypted         = try(each.value.ebs_encrypted, false)
  kms_key_id        = try(each.value.ebs_encrypted == false ? null : each.value.kms_key_id != null ? each.value.kms_key_id : data.aws_ebs_default_kms_key.current.key_arn, null)

  tags = merge(var.global_tags, { Name = each.value.name })
}

resource "aws_volume_attachment" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  device_name  = each.value.ebs_device_name
  instance_id  = aws_instance.this.id
  volume_id    = aws_ebs_volume.this[each.key].id
  force_detach = try(each.value.force_detach, false)
  skip_destroy = try(each.value.skip_destroy, false)
}
