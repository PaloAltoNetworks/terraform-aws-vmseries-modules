
#### Panorama AMI ID Lookup based on license type, region, version ####
data "aws_ami" "this" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = [var.pano_license_type_map[var.pano_license_type]]
  }

  filter {
    name   = "name"
    values = ["Panorama-AWS-${var.panorama_version}*"]
  }
}


locals {
  logger_panoramas = { for name, panorama in var.panoramas : name => panorama if contains(keys(panorama), "ebs") }
}


#### Create the Panorama Instances ####
resource "aws_instance" "this" {
  for_each                             = var.panoramas
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  ami                                  = data.aws_ami.this.id
  instance_type                        = each.value.instance_type
  availability_zone                    = each.value.availability_zone
  tags = merge(
    {
      "Name" = each.value.name
    },
    var.global_tags, each.value.local_tags
  )

  root_block_device {
    delete_on_termination = true
  }

  key_name   = each.value.ssh_key_name
  monitoring = false

  private_ip                  = lookup(each.value, "private_ip", null)
  associate_public_ip_address = lookup(each.value, "public_ip", null)

  vpc_security_group_ids = [var.security_groups_map[each.value.security_groups]]
  subnet_id              = var.subnets_map[each.value.subnet_id]
}


resource "aws_ebs_volume" "this" {
  for_each          = local.logger_panoramas
  availability_zone = each.value.availability_zone
  encrypted         = lookup(each.value.ebs, "encrypted", null)
  iops              = lookup(each.value.ebs, "iops", null)
  size              = lookup(each.value.ebs, "size", null)
  snapshot_id       = lookup(each.value.ebs, "snapshot_id", null)
  type              = lookup(each.value.ebs, "type", null)
  kms_key_id        = lookup(each.value.ebs, "kms_key_id", null)
  tags = merge({
    "Name" = each.key
    },
    var.global_tags,
    lookup(each.value, "tags", {})
  )
}


resource "aws_volume_attachment" "this" {
  for_each     = local.logger_panoramas
  device_name  = each.value.ebs.device_name
  instance_id  = aws_instance.this[each.key].id
  volume_id    = aws_ebs_volume.this[each.key].id
  force_detach = lookup(each.value, "force_detach", null)
  skip_destroy = lookup(each.value, "skip_destroy", null)
}
