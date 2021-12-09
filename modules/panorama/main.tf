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
  availability_zone = var.availability_zone
  size              = var.ebs_size
  encrypted         = var.ebs_encrypted
  kms_key_id        = var.ebs_encrypted == false ? null : var.kms_key_id != null ? var.kms_key_id : data.aws_ebs_default_kms_key.current.key_arn

  tags = merge(var.global_tags, { Name = "${var.name}-ebs" })
}

resource "aws_volume_attachment" "this" {
  device_name  = var.ebs_device_name
  instance_id  = aws_instance.this.id
  volume_id    = aws_ebs_volume.this.id
  force_detach = var.force_detach
  skip_destroy = var.skip_destroy
}
