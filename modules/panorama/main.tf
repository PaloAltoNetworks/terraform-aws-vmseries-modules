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
  }

  tags = merge(var.global_tags, { Name = var.name })
}

# Create Elastic IP
resource "aws_eip" "this" {
  count = var.create_public_ip ? 1 : 0

  instance = aws_instance.this.id
  vpc      = true

  tags = merge(var.global_tags, { Name = var.name })
}

# Retrieve KMS key for EBS encryption - key_id can be in 4 formats: key ID, key ARN, alias name or alias ARN.
# In order to not force replacement of aws_ebs_volume, because in Terraform state kms_key_id is stored
# in key ID format, we are retreving KMS key. Attribute arn from data source is always key ARN required in aws_ebs_volume.
data "aws_kms_key" "current_arn" {
  count = var.ebs_kms_key_alias != null ? 1 : 0
  key_id = var.ebs_kms_key_alias
}

resource "aws_ebs_volume" "this" {
  for_each = { for k, v in var.ebs_volumes : k => v }

  availability_zone = var.availability_zone
  size              = try(each.value.ebs_size, "2000")
  encrypted         = try(each.value.ebs_encrypted, false)
  kms_key_id        = try(data.aws_kms_key.current_arn[0].arn, null)

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
