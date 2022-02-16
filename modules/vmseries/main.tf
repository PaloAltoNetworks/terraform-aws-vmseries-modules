# PA VM AMI ID lookup based on version and license type (determined by product code)
data "aws_ami" "this" {
  count = var.vmseries_ami_id != null ? 0 : 1

  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.vmseries_version}*"]
  }
  filter {
    name   = "product-code"
    values = [var.vmseries_product_code]
  }
}

# The default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

# Network Interfaces
resource "aws_network_interface" "this" {
  for_each = var.interfaces

  subnet_id         = each.value.subnet_id
  private_ips       = lookup(each.value, "private_ips", null)
  source_dest_check = lookup(each.value, "source_dest_check", false)
  security_groups   = lookup(each.value, "security_group_ids", null)
  description       = lookup(each.value, "description", null)
  tags              = merge(var.tags, { Name = each.value.name })
}

# Create and/or associate EIPs
resource "aws_eip" "this" {
  for_each = { for k, v in var.interfaces : k => v if try(v.create_public_ip, false) }

  vpc               = true
  network_interface = aws_network_interface.this[each.key].id
  public_ipv4_pool  = lookup(each.value, "public_ipv4_pool", "amazon")
  tags              = merge(var.tags, { Name = "${each.value.name}-eip" })
}

resource "aws_eip_association" "this" {
  for_each = { for k, v in var.interfaces : k => v if try(v.eip_allocation_id, false) }

  allocation_id        = each.value.eip_allocation_id
  network_interface_id = aws_network_interface.this[each.key].id

  depends_on = [
    # Workaround for:
    # Error associating EIP: IncorrectInstanceState: The pending-instance-creation instance to which 'eni' is attached is not in a valid state for this operation
    aws_instance.this
  ]
}

# Create PA VM-series instances
resource "aws_instance" "this" {

  ami                                  = coalesce(var.vmseries_ami_id, data.aws_ami.this[0].id)
  iam_instance_profile                 = var.iam_instance_profile
  instance_type                        = var.instance_type
  key_name                             = var.ssh_key_name
  disable_api_termination              = false
  ebs_optimized                        = true
  instance_initiated_shutdown_behavior = "stop"
  monitoring                           = false

  user_data = base64encode(var.bootstrap_options)

  root_block_device {
    delete_on_termination = true
    encrypted             = var.ebs_encrypted
    kms_key_id            = var.ebs_encrypted == false ? null : var.ebs_kms_key_id != null ? var.ebs_kms_key_id : data.aws_ebs_default_kms_key.current.key_arn
    tags                  = merge(var.tags, { Name = var.name })
  }

  # Attach primary interface to the instance
  dynamic "network_interface" {
    for_each = { for k, v in var.interfaces : k => v if v.device_index == 0 }

    content {
      device_index         = 0
      network_interface_id = aws_network_interface.this[network_interface.key].id
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_network_interface_attachment" "this" {
  for_each = { for k, v in var.interfaces : k => v if v.device_index > 0 }

  instance_id          = aws_instance.this.id
  network_interface_id = aws_network_interface.this[each.key].id
  device_index         = each.value.device_index
}
