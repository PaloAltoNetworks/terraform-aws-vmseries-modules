#### Panorama AMI ID Lookup based on license type, region, version ####
data "aws_ami" "this" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Panorama-AWS-${var.panorama_version}*"]
  }

  filter {
    name   = "product-code"
    values = ["eclz7j04vu9lf8ont8ta3n17o"] // Product code for Panorama BYOL license
  }
}

// Create the Panorama Instance
resource "aws_instance" "this" {
  ami                                  = data.aws_ami.this.id
  instance_type                        = var.instance_type
  availability_zone                    = var.availability_zone
  key_name                             = var.ssh_key_name
  associate_public_ip_address          = var.public_ip_address //Check if EIP is automatically created if set to "true"
  private_ip                           = var.private_ip_address
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  monitoring                           = false
  vpc_security_group_ids               = var.vpc_security_group_ids

  root_block_device {
    delete_on_termination = true
  }

  tags = merge(var.global_tags, { Name = var.name })
}

# The default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

data "aws_kms_key" "current" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
}

resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = var.size
  encrypted         = var.encrypted
  kms_key_id        = var.encrypted == false ? null : var.kms_key_id != null ? var.kms_key_id : data.aws_kms_key.current.arn

  tags = merge(var.global_tags, { Name = var.name })
}

resource "aws_volume_attachment" "this" {
  device_name  = var.device_name
  instance_id  = aws_instance.this.id
  volume_id    = aws_ebs_volume.this.id
  force_detach = var.force_detach
  skip_destroy = var.skip_destroy
}
