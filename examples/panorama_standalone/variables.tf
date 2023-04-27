### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  default     = ""
  type        = string
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
  default     = {}
  type        = map(any)
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
}

### VPC
variable "vpcs" {
  description = <<-EOF
  A map defining VPCs with security groups and subnets.

  Following properties are available:
  - `name`: VPC name
  - `cidr`: CIDR for VPC
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `set`: internal identifier referenced by main.tf
  - `routes`: map of routes with properties:
     - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
     - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
     - `next_hop_type` - internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint

  Example:
  ```
  {
    security_vpc = {
      name = "security-vpc"
      cidr = "10.100.0.0/16"
      security_groups = {
        panorama_mgmt = {
          name = "panorama_mgmt"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
            https = {
              description = "Permit HTTPS"
              type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
              cidr_blocks = ["130.41.247.0/24"]
            }
            ssh = {
              description = "Permit SSH"
              type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
              cidr_blocks = ["130.41.247.0/24"]
            }
          }
        }
      }
      subnets = {
        "10.100.0.0/24"  = { az = "eu-central-1a", set = "mgmt" }
        "10.100.64.0/24" = { az = "eu-central-1b", set = "mgmt" }
      }
      routes = {
        mgmt_default = {
          vpc_subnet    = "security_vpc-mgmt"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "security_vpc"
          next_hop_type = "internet_gateway"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    cidr = string
    security_groups = map(object({
      name = string
      rules = map(object({
        description = string
        type        = string,
        from_port   = string
        to_port     = string,
        protocol    = string
        cidr_blocks = list(string)
      }))
    }))
    subnets = map(object({
      az  = string
      set = string
    }))
    routes = map(object({
      vpc_subnet    = string
      to_cidr       = string
      next_hop_key  = string
      next_hop_type = string
    }))
  }))
}

### PANORAMA
variable "panorama" {
  description = <<-EOF
  A map defining Panorama instances

  Following properties are available:
  - `instances`: map of Panorama instances
  - `panos_version`: PAN-OS version used for Panorama
  - `network`: definition of network settings in object with attributes:
    - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
    - `vpc_subnet`: key of the VPC and subnet connected by '-' character
    - `security_group`: security group assigned to ENI used by Panorama
    - `create_public_ip`: true, if public IP address for management should be created
  - `ebs`: EBS settings defined in object with attributes:
    - `volumes`: list of EBS volumes attached to each instance
    - `kms_key_alias`: KMS key alias used for encrypting Panorama EBS
  - `iam`: IAM settings in object with attrbiutes:
    - `create_role`: enable creation of IAM role
    - `role_name`: name of the role to create or use existing one

  Example:
  ```
  {
    panorama = {
      instances = {
        "01" = { az = "eu-central-1a" }
      }

      panos_version = "10.2.3"

      network = {
        vpc              = "security_vpc"
        vpc_subnet       = "security_vpc-mgmt"
        security_group   = "panorama_mgmt"
        create_public_ip = true
      }

      ebs = {
        volumes = [
          {
            name            = "ebs-1"
            ebs_device_name = "/dev/sdb"
            ebs_size        = "2000"
            ebs_encrypted   = true
          },
          {
            name            = "ebs-2"
            ebs_device_name = "/dev/sdc"
            ebs_size        = "2000"
            ebs_encrypted   = true
          }
        ]
        kms_key_alias = "aws/ebs"
      }

      iam = {
        create_role = true
        role_name   = "panorama-read-only"
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    instances = map(object({
      az = string
    }))

    panos_version = string

    network = object({
      vpc              = string
      vpc_subnet       = string
      security_group   = string
      create_public_ip = bool
    })

    ebs = object({
      volumes = list(object({
        name            = string
        ebs_device_name = string
        ebs_size        = string
        ebs_encrypted   = bool
      }))
      kms_key_alias = string
    })

    iam = object({
      create_role = bool
      role_name   = string
    })
  }))
}
