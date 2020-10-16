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


output "instance_id" {
  value       = aws_instance.firewall.id
  description = "Instance ID of created firewall."
}

output "mgmt_public_ip" {
  value       = concat(aws_eip.mgmt.*.public_ip, [""])[0]
  description = "Public IP address of firewall management interface."
}

output "mgmt_interface_id" {
  value       = aws_network_interface.mgmt.id
  description = "Interface ID of created firewall management interface."
}

output "eth1_public_ip" {
  value       = concat(aws_eip.eth1.*.public_ip, [""])[0]
  description = "Public IP address of firewall ethernet1/1 interface."
}

output "eth1_interface_id" {
  value       = aws_network_interface.eth1.id
  description = "Interface ID of created firewall ethernet1/1 interface."
}

output "eth2_interface_id" {
  value       = aws_network_interface.eth2.id
  description = "Interface ID of created firewall ethernet1/2 interface."
}
