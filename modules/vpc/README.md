# Base AWS Infrrastructure Resources for VM-Series

## Overview  
Create VPC, Subnets, Security Groups, Transit Gateways, Route Tables, and other optional resources to support a Palo Alto Networks VM-Series Deployment.

### Usage
```
provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "git::https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/modules/vpc?ref=v0.1.0"

prefix_name_tag = "my-prefix"   // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
 Environment = "us-east-1"
 Group       = "SecOps"
 Managed_By  = "Terraform"
 Description = "Example Usage"
*}

vpc = {
 vmseries_vpc = {
  existing              = false
   name                  = "vmseries-vpc"
   cidr_block            = "10.100.0.0/16"
   secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]
   instance_tenancy      = "default"
   enable_dns_support    = true
   enable_dns_hostname   = true
   igw                   = true
 }
*}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13 |
| aws | ~> 3 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| global\_tags | Optional Map of arbitrary tags to apply to all resources | `map(any)` | `{}` | no |
| prefix\_name\_tag | Prepended to name tags for various resources. Leave as empty string if not desired. | `string` | `""` | no |
| subnets | Map of subnets to create in the vpc. | `any` | `{}` | no |
| vpc | Map of parameters for the VPC. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| route\_table\_ids | n/a |
| subnet\_ids | n/a |
| vpc | VPC attributes |

