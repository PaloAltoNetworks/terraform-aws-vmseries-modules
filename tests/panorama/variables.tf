### General

variable "region" {
  description = "AWS Region."
  default     = "us-east-1"
  type        = string
}

variable "name_prefix" {
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

variable "vpc_cidr" {
  description = "AWS VPC Cidr block."
  type        = string
}

variable "vpc_routes_outbound_destin_cidrs" {
  description = "VPC Routes outbound cidr"
  type        = list(string)
}

variable "vpc_subnets" {
  description = "Security VPC subnets CIDR"
  default     = {}
  type        = map(any)
}

variable "vpc_security_groups" {
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

variable "panorama_create_public_ip" {
  description = "Public access to Panorama."
  default     = false
  type        = bool
}

variable "panorama_version" {
  description = "Panorama OS Version."
  default     = "10.2.0"
  type        = string
}

variable "panorama_ebs_volumes" {
  description = "List of Panorama volumes"
  default     = []
  type        = list(any)
}

variable "panorama_ebs_encrypted" {
  description = "Whether to enable EBS encryption on volumes.."
  default     = true
  type        = bool
}

variable "panorama_ebs_kms_key_alias" {
  description = "KMS key alias used for encrypting Panorama EBS."
  default     = ""
  type        = string
}

### IAM Instance Role

variable "panorama_create_iam_instance_profile" {
  description = "Enable creation of IAM Instance Profile and attach it to Panorama."
  default     = false
  type        = bool
}

variable "panorama_create_iam_role" {
  description = "Enable creation of IAM Role for IAM Instance Profile."
  default     = false
  type        = bool
}

variable "panorama_iam_policy_name" {
  description = <<-EOF
If you want to use existing IAM Policy in Terraform created IAM Role, provide IAM Role name with this variable."
EOF
  default     = ""
  type        = string
}

variable "panorama_existing_iam_role_name" {
  description = <<-EOF
If you want to use existing IAM Role as IAM Instance Profile use this variable to provide IAM Role name."
EOF
  default     = ""
  type        = string
}
