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

variable global_tags {
  description = "Optional Map of arbitrary tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable prefix {
  type    = string
  default = "bootstrap"
}

variable iam_instance_profile_name {
  description = "(optional) Name of the instance profile to create. If empty, name will be generated automatically"
  type        = string
  default     = ""
}

variable "bootstrap_directories" {
  description = "The directories comprising the bootstrap package"
  default = [
    "config/",
    "content/",
    "software/",
    "license/",
    "plugins/"
  ]
}


### Variables below go to the init-cfg.txt
variable "hostname" {
  default     = ""
  description = "The hostname of the VM-series instance"
  type        = string
}

variable "panorama-server" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "The FQDN or IP address of the primary Panorama server"
  type        = string
}

variable "panorama-server2" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "The FQDN or IP address of the secondary Panorama server"
  type        = string
}

variable "tplname" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "The Panorama template stack name"
  type        = string
}

variable "dgname" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "The Panorama device group name"
  type        = string
}

variable "dns-primary" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "The IP address of the primary DNS server"
  type        = string
}

variable "dns-secondary" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "The IP address of the secondary DNS server"
  type        = string
}

variable "vm-auth-key" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "Virtual machine authentication key"
  type        = string
}

variable "op-command-modes" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  default     = ""
  description = "Set jumbo-frame and/or mgmt-interface-swap"
  type        = string
}
