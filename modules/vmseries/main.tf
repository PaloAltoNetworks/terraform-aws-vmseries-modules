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

  name_regex = "^PA-VM-AWS-${var.vmseries_version}-[[:alnum:]]{8}-([[:alnum:]]{4}-){3}[[:alnum:]]{12}$"
}

# Retrieve the default KMS key in the current region for EBS encryption
data "aws_ebs_default_kms_key" "current" {
  count = var.ebs_encrypted ? 1 : 0
}

# Retrieve an alias for the KMS key for EBS encryption
data "aws_kms_alias" "current_arn" {
  count = var.ebs_encrypted ? 1 : 0
  name  = coalesce(var.ebs_kms_key_alias, data.aws_ebs_default_kms_key.current[0].key_arn)
}

# Network Interfaces
resource "aws_network_interface" "this" {
  for_each = var.interfaces

  subnet_id         = each.value.subnet_id
  private_ips       = lookup(each.value, "private_ips", null)
  source_dest_check = lookup(each.value, "source_dest_check", false)
  security_groups   = lookup(each.value, "security_group_ids", null)
  description       = lookup(each.value, "description", null)
  tags              = merge(var.tags, { Name = coalesce(try(each.value.name, null), "${var.name}-${each.key}") })
}

# Create and/or associate EIPs
resource "aws_eip" "this" {
  for_each = { for k, v in var.interfaces : k => v if try(v.create_public_ip, false) }

  domain            = var.eip_domain
  network_interface = aws_network_interface.this[each.key].id
  public_ipv4_pool  = lookup(each.value, "public_ipv4_pool", "amazon")
  tags              = merge(var.tags, { Name = coalesce(try(each.value.name, null), "${var.name}-${each.key}") })
}

resource "aws_eip_association" "this" {
  for_each = { for k, v in var.interfaces : k => v if lookup(v, "eip_allocation_id", null) != null }

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

  ami                                  = coalesce(var.vmseries_ami_id, try(data.aws_ami.this[0].id, null))
  iam_instance_profile                 = var.iam_instance_profile
  instance_type                        = var.instance_type
  key_name                             = var.ssh_key_name
  disable_api_termination              = var.enable_instance_termination_protection
  ebs_optimized                        = true
  instance_initiated_shutdown_behavior = "stop"
  monitoring                           = false

  dynamic "metadata_options" {
    for_each = var.enable_imdsv2 ? [1] : []
    content {
      http_endpoint = "enabled"
      http_tokens   = "required"
    }
  }

  user_data = base64encode(var.bootstrap_options)

  root_block_device {
    delete_on_termination = true
    encrypted             = var.ebs_encrypted
    kms_key_id            = var.ebs_encrypted == false ? null : data.aws_kms_alias.current_arn[0].target_key_arn
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

  # If volume_tags are not defined, then module is NOT idempotent. If after deployment terraform plan is executed,
  # then update in-place is planned for resource "aws_instance" "this" with below change:
  # + volume_tags = {}
  volume_tags = merge(var.tags, { Name = var.name })

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

resource "aws_network_interface_attachment" "this" {
  for_each = { for k, v in var.interfaces : k => v if v.device_index > 0 }

  instance_id          = aws_instance.this.id
  network_interface_id = aws_network_interface.this[each.key].id
  device_index         = each.value.device_index
}
