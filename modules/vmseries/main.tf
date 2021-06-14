#### PA VM AMI ID Lookup based on license type, region, version ####
data "aws_ami" "this" {
  count       = var.custom_ami_id == null ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.panos_version}*"]
  }

  filter {
    name   = "product-code"
    values = [var.fw_product_map[var.fw_product]]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["aws-marketplace"]
}

# The default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

data "aws_kms_key" "current" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
}

###################
# Network Interfaces
###################
resource "aws_network_interface" "this" {
  for_each = { for k, v in var.interfaces : k => v } # convert list to map

  subnet_id         = each.value.subnet_id
  private_ips       = try([each.value.private_ip_address], null)
  source_dest_check = try(each.value.source_dest_check, false)
  security_groups   = try(each.value.security_groups, null)
  description       = try(each.value.description, null)
  tags              = merge(var.tags, { Name = each.value.name })
}

###################
# Create and Associate EIPs
###################
resource "aws_eip" "this" {
  for_each = { for k, v in var.interfaces : k => v if try(v.create_public_ip, false) && try(v.eip_allocation_id, false) == false }

  vpc              = true
  public_ipv4_pool = try(each.value.public_ipv4_pool, "amazon")
  tags             = merge(var.tags, { Name = "${each.value.name}-eip" })
}

resource "aws_eip_association" "this" {
  for_each = { for k, v in var.interfaces : k => v if try(v.create_public_ip, false) || try(v.eip_allocation_id, false) != false }

  allocation_id        = try(aws_eip.this[each.key].id, var.interfaces[each.key].eip_allocation_id)
  network_interface_id = aws_network_interface.this[each.key].id
}


################
# Create PA VM-series instances
################
resource "aws_instance" "this" {
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  ami                                  = var.custom_ami_id != null ? var.custom_ami_id : data.aws_ami.this[0].id
  instance_type                        = var.instance_type
  key_name                             = var.ssh_key_name
  user_data                            = var.user_data
  monitoring                           = false
  iam_instance_profile                 = var.iam_instance_profile

  root_block_device {
    delete_on_termination = "true"
    encrypted             = var.root_block_device_encrypted
    kms_key_id            = var.root_block_device_encrypted == false ? null : var.root_block_device_encryption_kms_key_id != null ? var.root_block_device_encryption_kms_key_id : data.aws_kms_key.current.arn
    tags                  = merge(var.tags, { Name = var.name })
  }

  # Attach primary interface to the instance
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.this[0].id
  }

  tags = merge(var.tags, { Name = var.name })
}

# Attach interfaces to the instance except the first interface. 
# First interface will be directly attached to the EC2 instance. See 'aws_instance' resource 
resource "aws_network_interface_attachment" "this" {
  for_each = { for k, v in aws_network_interface.this : k => v if k > 0 }

  instance_id          = aws_instance.this.id
  network_interface_id = aws_network_interface.this[each.key].id
  device_index         = each.key
}
