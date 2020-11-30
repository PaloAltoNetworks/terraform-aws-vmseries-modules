variable subnets_map {
  type        = map(any)
  description = "Map of subnet name to ID, can be passed from remote state output or data source"
  default     = {}
  # Example Format:
  # subnets_map = {
  #   "panorama-mgmt-1a" = "subnet-0e1234567890"
  #   "panorama-mgmt-1b" = "subnet-0e1234567890"
  # } 
}

variable security_groups_map {
  type        = map(any)
  description = "Map of security group name to ID, can be passed from remote state output or data source"
  default     = {}
  # Example Format:
  # security_groups_map = {
  #   "panorama-mgmt-inbound-sg" = "sg-0e1234567890"
  #   "panorama-mgmt-outbound-sg" = "sg-0e1234567890"
  # } 
}

variable "buckets_map" {
  type        = map(any)
  description = "Map of S3 Bucket name to ID, can be passed from remote state output or data source"
  default     = {}
  # Example Format:
  # buckets_map = {
  #   "bootstrap_bucket1 = {
  #      arn = "arn:aws-us-gov:s3:::bootstrap_bucket1
  #      name = "bootstrap_bucket1"
  #   }
  #   "bootstrap_bucket2 = {
  #      arn = "arn:aws-us-gov:s3:::bootstrap_bucket2
  #      name = "bootstrap_bucket2"
  #   }
  #}
}

variable "route_tables_map" {
  type        = map(any)
  description = "Map of Route Tables Name to ID, can be passed from remote state output or data source"
  default     = {}
}

variable "region" {
  description = "AWS Region"
}

variable "tags" {
  description = "Map of additional tags to apply to all resources"
  type        = map
  default     = {}
}

variable prefix_name_tag {
  type        = string
  default     = ""
  description = "Prefix used to build name tags for resources"
}

variable "prefix_bootstrap" {
  type = string
  default = "pan-bootstrap"
    description = "Prefix used to build bootstrap related resources"
}

variable "interfaces" {
  description = "Map of interfaces to create with optional parameters"
  # Required: name, subnet_name, security_group
  # Optional: eip, source_dest_check
  default = [ # Example
    {
      name              = "ingress-fw1-mgmt"
      source_dest_check = true
      subnet_name       = "ingress-mgmt-subnet-az1"
      security_group    = "sg-123456789"
      eip               = "ingress-fw1-mgmt-eip"
    },
    {
      name              = "ingress-fw1-trust"
      source_dest_check = false
      subnet_name       = "ingress-trust-subnet-az1"
      security_group    = "sg-123456789"
  }]
}

variable "firewalls" {
  description = "Map of vm-series firewalls to create with interface mappings"
  # Required: name, interfaces(map with name and index)
  default = [{ # Example
    name                = "ingress-fw1"
    mgmt-interface-swap = "disable" # "enable" for interface swap, any other string will omit user-data for interface swap 
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
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances"
  default     = ""
}

# Firewall version for AMI lookup

variable "fw_version" {
  description = "Select which FW version to deploy"
  default     = "9.0.6"
  # Acceptable Values Below
  #default = "9.1.0"
  #default = "8.1.9"
  #default = "8.1.0"
}

# License type for AMI lookup
variable "fw_license_type" {
  description = "Select License type (byol/payg1/payg2)"
  default     = "byol"
}

# Product code map based on license type for ami filter
variable "fw_license_type_map" {
  type = map(string)
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

variable "addtional_interfaces" {
  description = "Map additional interfaces after initial EC2 deployment"
  type        = map(any)
  default     = {}
}

variable "rts_to_fw_eni" {
  type        = map(any)
  default     = {}
  description = "Map of RTs from base_infra output and the FW ENI to map default route to"
}
