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


variable "vpc_id" {
  description = "VPC to create firewall instance in."
}

variable "key_name" {
  description = "Key pair name to provision instances with."
}

variable "mgmt_subnet_id" {
  description = "Subnet ID for firewall management interface."
}

variable "mgmt_ip" {
  description = "Internal IP address for firewall management interface."
}

variable "mgmt_sg_id" {
  description = "Security group ID for firewall management interface."
}

variable "eth1_subnet_id" {
  description = "Subnet ID for firewall ethernet1/1 interface."
}

variable "eth1_ip" {
  description = "Internal IP address for firewall ethernet1/1 interface."
}

variable "eth1_sg_id" {
  description = "Security group ID for firewall ethernet1/1 interface."
}

variable "eth2_subnet_id" {
  description = "Subnet ID for firewall ethernet1/2 interface."
}

variable "eth2_ip" {
  description = "Internal IP address for firewall ethernet1/2 interface."
}

variable "eth2_sg_id" {
  description = "Security group ID for firewall ethernet1/2 interface."
}

# Optional variables

variable "ami" {
  description = "Specific firewall AMI to deploy.  If not specified, AMI will be looked up."
  default     = ""
}

variable "instance_type" {
  description = "Instance type for firewall."
  default     = "m4.xlarge"
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile used to bootstrap firewall."
  default     = ""
}

variable "bootstrap_bucket" {
  description = "S3 bucket containing bootstrap configuration."
  default     = ""
}

variable "create_mgmt_eip" {
  description = "Create and assign elastic IP to management interface."
  type        = bool
  default     = true
}

variable "create_eth1_eip" {
  description = "Create and assign elastic IP to ethernet1/1 interface."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources."
  default = {
    Name = "Firewall"
  }
}

variable "panos_version" {
  type        = string
  description = "PAN-OS version to deploy (if AMI is not specified)."
  default     = "9.1"
}

variable "panos_license_type" {
  type        = string
  description = "PAN-OS license type.  Can be one of 'byol', 'bundle1', 'bundle2'."
  default     = "byol"
}

# Product codes for PAN-OS versions before 9.1.
variable "license_type_map_old" {
  type = map(string)

  default = {
    "byol"    = "6njl1pau431dv1qxipg63mvah"
    "bundle1" = "6kxdw3bbmdeda3o6i1ggqt4km"
    "bundle2" = "806j2of0qy5osgjjixq9gqc6g"
  }
}

# Product codes for PAN-OS versions 9.1 and later.
variable "license_type_map" {
  type = map(string)

  default = {
    "byol"    = "6njl1pau431dv1qxipg63mvah"
    "bundle1" = "e9yfvyj3uag5uo5j2hjikv74n"
    "bundle2" = "hd44w1chf26uv4p52cdynb2o"
  }
}
