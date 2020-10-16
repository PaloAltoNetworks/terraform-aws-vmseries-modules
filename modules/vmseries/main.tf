############################################################################################
# Copyright 2020 Palo Alto Networks.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
############################################################################################

# Pick the right license type map based on the PAN-OS version.
locals {
  license_type_map = (contains(["8.1", "9.0"], var.panos_version)) ? var.license_type_map_old : var.license_type_map
}

data "aws_ami" "panos" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "owner-alias"
    values = ["aws-marketplace"]
  }

  filter {
    name   = "product-code"
    values = [local.license_type_map[var.panos_license_type]]
  }

  filter {
    name   = "name"
    values = ["PA-VM-AWS*${var.panos_version}*"]
  }
}

resource "aws_instance" "firewall" {
  ami           = (var.ami != "") ? var.ami : data.aws_ami.panos.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"

  ebs_optimized = true

  root_block_device {
    volume_type           = "gp2"
    delete_on_termination = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.mgmt.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eth1.id
  }

  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.eth2.id
  }

  iam_instance_profile = var.iam_instance_profile
  user_data            = base64encode(join("", list("vmseries-bootstrap-aws-s3bucket=", var.bootstrap_bucket)))

  tags = merge(var.tags)
}

resource "aws_network_interface" "mgmt" {
  subnet_id       = var.mgmt_subnet_id
  private_ips     = [var.mgmt_ip]
  security_groups = [var.mgmt_sg_id]

  tags = merge(var.tags, { "Name" = format("%s-Mgmt", var.tags.Name) })
}

resource "aws_network_interface" "eth1" {
  subnet_id         = var.eth1_subnet_id
  private_ips       = [var.eth1_ip]
  security_groups   = [var.eth1_sg_id]
  source_dest_check = false

  tags = merge(var.tags, { "Name" = format("%s-Eth1", var.tags.Name) })
}

resource "aws_network_interface" "eth2" {
  subnet_id         = var.eth2_subnet_id
  private_ips       = [var.eth2_ip]
  security_groups   = [var.eth2_sg_id]
  source_dest_check = false

  tags = merge(var.tags, { "Name" = format("%s-Eth2", var.tags.Name) })
}

resource "aws_eip" "mgmt" {
  count = var.create_mgmt_eip ? 1 : 0

  vpc = true
}

resource "aws_eip_association" "mgmt" {
  count = var.create_mgmt_eip ? 1 : 0

  allocation_id        = aws_eip.mgmt[0].id
  network_interface_id = aws_network_interface.mgmt.id
}

resource "aws_eip" "eth1" {
  count = var.create_eth1_eip ? 1 : 0

  vpc = true
}

resource "aws_eip_association" "eth1" {
  count = var.create_eth1_eip ? 1 : 0

  allocation_id        = aws_eip.eth1[0].id
  network_interface_id = aws_network_interface.eth1.id
}
