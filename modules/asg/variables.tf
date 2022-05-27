variable "fw_version" {
  description = "Select which FW version to deploy."
  default     = "10.0.3"
}

variable "fw_license_type" {
  description = "Select License type (byol/payg1/payg2)."
  default     = "byol"
}

variable "fw_license_type_map" {
  description = <<-EOF
  Map of the VM-Series Firewall licence types and corresponding VM-Series Firewall Amazon Machine Image (AMI) ID.
  The key is the licence type, and the value is the VM-Series Firewall AMI ID."
  EOF
  default = {
    "byol"  = "6njl1pau431dv1qxipg63mvah"
    "payg1" = "6kxdw3bbmdeda3o6i1ggqt4km"
    "payg2" = "806j2of0qy5osgjjixq9gqc6g"
  }
  type = map(string)
}

variable "fw_instance_type" {
  description = "EC2 Instance Type."
  default     = "m5.xlarge"
  type        = string
}

variable "name_prefix" {
  description = "All resource names will be prepended with this string."
  type        = string
}

variable "asg_name" {
  description = "Name of the autoscaling group to create."
  default     = "asg1"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances."
  type        = string
}

variable "bootstrap_options" {
  description = "Bootstrap options to put into userdata."
  default     = {}
  type        = map(any)
}

variable "interfaces" {
  type = list(any)
}

variable "subnet_ids" {
  description = "Map of subnet ids"
  type        = map(any)
}

variable "security_group_ids" {
  description = "Map of security group ids"
  type        = map(any)
}

variable "lifecycle_hook_timeout" {
  description = "How long should we wait in seconds for the Lambda hook to finish."
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

variable "warm_pool_state" {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). Ignored when `max_group_prepared_capacity` is 0 (the default value)."
  default     = null
}

variable "warm_pool_min_size" {
  description = "See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool). Ignored when `max_group_prepared_capacity` is 0 (the default value)."
  default     = null
}

variable "max_group_prepared_capacity" {
  description = "Set to non-zero to activate the Warm Pool of instances. See the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool)."
  default     = 0
}

variable "global_tags" {
  type = map(any)
}
