### General

variable "region" {
  description = "AWS Region."
  default     = "us-east-1"
  type        = string
}

variable "create_ssh_key" {
  description = "Create ssh key."
  default     = false
  type        = bool
}

variable "prefix" {
  description = "Prefix use for creating unique names."
  default     = ""
  type        = string
}

variable "global_tags" {
  description = <<-EOF
  A map of tags to assign to the resources.
  If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  EOF
  default     = {}
  type        = map(any)
}

### Network

variable "security_vpc_name" {
  description = "VPC Name."
  default     = "security-vpc"
  type        = string
}

variable "security_vpc_cidr" {
  description = "AWS VPC Cidr block."
  type        = string
}

variable "security_vpc_routes_outbound_destin_cidrs" {
  description = "VPC Routes outbound cidr"
  type        = list(string)
}

variable "security_vpc_subnets" {
  description = "Security VPC subnets CIDR"
  default     = {}
  type        = map(any)
}

variable "security_vpc_security_groups" {
  description = <<-EOF
  Security VPC security groups settings.
  Structure looks like this:
  ```
  {
    security_group_name = {
      {
        name = "security_group_name"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }
  }
  ```
  EOF
  type        = map(any)
}

### Panorama

variable "panorama_az" {
  description = "Availability zone where Panorama was be deployed."
  type        = string
}

variable "panorama_ssh_key" {
  description = "SSH key used to login into Panorama EC2 server."
  type        = string
}

variable "panorama_create_public_ip" {
  description = "Public access to Panorama."
  default     = false
  type        = bool
}

variable "panorama_version" {
  description = "Panorama OS Version."
  default     = "10.2"
  type        = string
}

variable "panorama_instance_name" {
  description = "Name of Panorama instance"
  default     = "pan-panorama"
  type        = string
}

variable "panorama_ebs_volumes" {
  description = "List of Panorama volumes"
  default     = []
  type        = list(any)
}

variable "panorama_enable_iam_read_only_policy" {
  description = "It enable Read Only IAM instance role policy on Panorama EC2 Instance."
  default     = false
  type        = bool
}

variable "panorama_create_custom_kms_key" {
  description = "Create custom KMS key for encrypt EBS in Panorama instance."
  default     = false
  type        = bool
}