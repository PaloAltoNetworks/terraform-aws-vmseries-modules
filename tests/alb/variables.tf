variable "global_tags" {}

variable "region" {
  description = "AWS region to use for the created resources."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resources created for tests"
  type        = string
}

variable "security_vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
}

variable "security_vpc_subnets" {
  description = "Map of subnets in VPC"
}

variable "security_vpc_security_groups" {
  description = "Map of security groups"
}

variable "application_lb_rules" {
  description = "A map of rules for the Application Load Balancer. See [modules documentation](../../modules/alb/README.md) for details."
  default     = {}
  type        = any
}

variable "application_lb_name" {
  description = "Name of the public Application Load Balancer placed in front of the Firewalls' public interfaces."
  default     = "public-alb"
  type        = string
}

variable "key_pair_name" {
  default = "Terratest_key_pair"
}

variable "app_vms" {
  description = <<-EOF
  Definition of an example "app" application VMs. They are based on the latest version of Bitnami's NGINX image.
  The structure of this map is similar to the one defining VM-Series, only one property is supported though: the Availability Zone the VM should be placed in.
  Example:

  ```
  app_vms = {
    "appvm01" = { az = "us-east-1b" }
    "appvm02" = { az = "us-east-1a" }
  }
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "app_vm_type" {
  description = "EC2 type for \"app\" VMs."
  default     = "t2.micro"
  type        = string
}

variable "app_vm_iam_instance_profile" {
  description = "IAM instance profile."
  default     = null
  type        = string
}
