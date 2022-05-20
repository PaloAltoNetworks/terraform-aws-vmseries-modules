locals {
  name = "${var.universal_name_prefix}${var.name}}"
}

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

resource "aws_kms_key" "panorama_instance_ebs_kms_key" {
  count = var.create_custom_kms_key_for_ebs ? 1 : 0

  description              = "KMS key used for encrypting Panorama instance EBS."
  deletion_window_in_days  = var.kms_delete_window_in_days
  customer_master_key_spec = var.kms_cmk_spec
}

resource "aws_kms_alias" "panorama_instance_ebs_kms_key" {
  count = var.create_custom_kms_key_for_ebs ? 1 : 0

  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.panorama_instance_ebs_kms_key[0].arn
}

# Create IAM role
resource "aws_iam_role" "panorama_read_only_role" {
  count       = var.create_read_only_iam_role ? 1 : 0
  name        = "${var.universal_name_prefix}PanoramaReadOnly"
  description = "Allow read-only access to AWS resources."

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags               = var.global_tags
}

# Attach IAM Policy to IAM Role

resource "aws_iam_policy_attachment" "panorama_iam_ro_attach" {
  count = var.create_read_only_iam_role ? 1 : 0

  name       = "${var.universal_name_prefix}panorama_ro_iam_policy_attachment"
  roles      = [aws_iam_role.panorama_read_only_role[0].name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "panorama_instance_profile" {
  count = var.create_read_only_iam_role ? 1 : 0

  name = "${var.universal_name_prefix}panorama_iam_att_profile"
  role = aws_iam_role.panorama_read_only_role[0].name
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
  iam_instance_profile                 = try(aws_iam_instance_profile.panorama_instance_profile[0].name, null)

  root_block_device {
    delete_on_termination = true
  }

  tags = merge(var.global_tags, { Name = local.name })
}

# Create Elastic IP
resource "aws_eip" "this" {
  count = var.create_public_ip ? 1 : 0

  instance = aws_instance.this.id
  vpc      = true

  tags = merge(var.global_tags, { Name = local.name })
}

# Get the default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

resource "aws_ebs_volume" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  availability_zone = var.availability_zone
  size              = try(each.value.ebs_size, "2000")
  encrypted         = try(each.value.ebs_encrypted, false)
  kms_key_id = try(each.value.ebs_encrypted == false ? null : each.value.kms_key_id != null ?
  each.value.kms_key_id : var.create_custom_kms_key_for_ebs == true ? try(aws_kms_key.panorama_instance_ebs_kms_key[0].arn) : data.aws_ebs_default_kms_key.current.key_arn, null)

  tags = merge(var.global_tags, { Name = try(each.value.name, local.name) })
}

resource "aws_volume_attachment" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  device_name  = each.value.ebs_device_name
  instance_id  = aws_instance.this.id
  volume_id    = aws_ebs_volume.this[each.key].id
  force_detach = try(each.value.force_detach, false)
  skip_destroy = try(each.value.skip_destroy, false)
}
