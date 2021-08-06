variable "subnets_map" {
  description = <<-EOF
  Map of subnet name to ID, can be passed from remote state output or data source.

  Example:

  ```
  subnets_map = {
    "panorama-mgmt-1a" = "subnet-0e1234567890"
    "panorama-mgmt-1b" = "subnet-0e1234567890"
  }
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "security_groups_map" {
  description = <<-EOF
  Map of security group name to ID, can be passed from remote state output or data source.

  Example:

  ```
  security_groups_map = {
    "panorama-mgmt-inbound-sg" = "sg-0e1234567890"
    "panorama-mgmt-outbound-sg" = "sg-0e1234567890"
  } 
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "buckets_map" {
  description = <<-EOF
  Map of S3 Bucket name to ID, can be passed from remote state output or data source.

  Example:

  ```
  buckets_map = {
    "bootstrap_bucket1 = {
       arn = "arn:aws-us-gov:s3:::bootstrap_bucket1
       name = "bootstrap_bucket1"
    }
    "bootstrap_bucket2 = {
       arn = "arn:aws-us-gov:s3:::bootstrap_bucket2
       name = "bootstrap_bucket2"
    }
  }
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "route_tables_map" {
  description = "Map of Route Tables Name to ID, can be passed from remote state output or data source."
  default     = {}
  type        = map(any)
}

variable "region" {
  description = "AWS Region"
}

variable "tags" {
  description = "Map of additional tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix_name_tag" {
  description = "Prefix used to build name tags for resources."
  default     = ""
  type        = string
}

# variable "prefix_bootstrap" {
#   type        = string
#   default     = "pan-bootstrap"
#   description = "Prefix used to build bootstrap related resources"
# }

variable "interfaces" {
  description = <<-EOF
  Map of interfaces to create with optional parameters.

  Required: name, subnet_name, security_group
  Optional: `eip_name`, `source_dest_check`.

  Example:
  ```
  interfaces = [
    {
      name              = "ingress-fw1-mgmt"
      eip_name          = "ingress-fw1-mgmt-eip"
      source_dest_check = true
      subnet_name       = "ingress-mgmt-subnet-az1"
      security_group    = "sg-123456789"
    },
    {
      name              = "ingress-fw1-trust"
      source_dest_check = false
      subnet_name       = "ingress-trust-subnet-az1"
      security_group    = "sg-123456789"
  }]
  ```
  EOF
}

variable "firewalls" {
  description = <<-EOF
  Map of VM-Series Firewalls to create with interface mappings.

  Required: `name`, `interfaces` (a map of names and indexes).

  Example:

  ```
  firewalls = [{
    name = "ingress-fw1"
    bootstrap_options = {
      mgmt-interface-swap = "disable" # Change to "enable" for interface swap
    }
    interfaces = [{
      name  = "ingress-fw1-mgmt"
      index = "0"
      },
      {
        name  = "ingress-fw1-untrust"
        index = "1"
      },
      {
        name  = "ingress-fw1-trust"
        index = "2"
    }]
  }]
  ```

  EOF
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances."
  default     = ""
}

# Firewall version for AMI lookup

variable "fw_version" {
  description = <<-EOF
  Select which VM-Series Firewall version to deploy.

  Example:

  ```
  #default = "9.1.0"
  #default = "8.1.9"
  #default = "8.1.0"
  ```
  EOF
  default     = "9.0.6"
  type        = string
}

# License type for AMI lookup
variable "fw_license_type" {
  description = "Select the VM-Series Firewall license type - available options: `byol`, `payg1`, `payg2`."
  default     = "byol"
}

# Product code map based on license type for ami filter
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
  type        = string
  default     = "m5.xlarge"
}

variable "addtional_interfaces" {
  description = "Map additional interfaces after initial EC2 deployment."
  type        = map(any)
  default     = {}
}

variable "rts_to_fw_eni" {
  description = "Map of RTs from base_infra output and the FW ENI to map default route to."
  type        = map(any)
  default     = {}
}
