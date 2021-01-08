variable "fw_version" {
  description = "Select which FW version to deploy"
  default     = "10.0.3"
}

variable "fw_license_type" {
  description = "Select License type (byol/payg1/payg2)"
  default     = "byol"
}

variable "fw_license_type_map" {
  description = "Product code map based on license type for ami filter"
  type        = map(string)
  default = {
    "byol"  = "6njl1pau431dv1qxipg63mvah"
    "payg1" = "6kxdw3bbmdeda3o6i1ggqt4km"
    "payg2" = "806j2of0qy5osgjjixq9gqc6g"
  }
}

variable "fw_instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "m5.xlarge"
}

variable "name_prefix" {
  description = "All resource names will be prepended with this string"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances"
  type        = string
}

variable "bootstrap_options" {
  description = "Bootstrap options to put into userdata"
  type        = map
  default     = {}
}

variable "interfaces" {
  type = list
}

variable "subnet_ids" {
  description = "Map of subnet ids"
  type        = map
}

variable "lifecycle_hook_timeout" {
  description = "How long should we wait for lambda to finish"
  type        = number
  default     = 300
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "global_tags" {
  type = map
}