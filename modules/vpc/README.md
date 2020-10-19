# VPC module for VM-Series

## Overview  

Module for sinlge VPC and all other optional base infrastructure resources to support various Palo Alto Networks VM-Series deployments. 



### Usage

See examples for more details of usage.

`main.tf`

```
provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "git::https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/modules/vpc?ref=v0.1.0"
  global_tags      = var.global_tags
  prefix_name_tag  = var.prefix_name_tag
  vpc              = var.vpc
  vpc_route_tables = var.vpc_route_tables
  subnets          = var.subnets
  nat_gateways     = var.nat_gateways
  vpn_gateways     = var.vpn_gateways
  vpc_endpoints    = var.vpc_endpoints
  security_groups  = var.security_groups
}
```

`terraform.tfvars`

```
region = "us-east-1"

prefix_name_tag = "vpc-all-options-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  managed-by = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

vpc = { // Module only designed for a single VPC. Set all params here. If existing = true, specify the Name tag of existing VPC
  vmseries-vpc = {
    existing              = false
    name                  = "my-vpc"
    cidr_block            = "10.100.0.0/16"
    secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]
    instance_tenancy      = "default"
    enable_dns_support    = true
    enable_dns_hostnames  = true
    internet_gateway      = true
    local_tags            = { "foo" = "bar" }
  }
}

vpc_route_tables = {
  mgmt        = { name = "mgmt", vgw_propagation = "vmseries-vgw", local_tags = { "foo" = "bar" } }
  public      = { name = "public" }
  igw-ingress = { name = "igw-ingress", igw_association = "vmseries-vpc" }
}

subnets = {
  # mgmt-1a       = { existing = true, name = "mgmt-1a" } // For brownfield, set existing = true with name tag of existing subnet
  mgmt-1a       = { name = "mgmt-1a", cidr = "10.100.0.0/25", az = "us-east-1a", rt = "mgmt", local_tags = { "foo" = "bar" } }
}

nat_gateways = {
  public-1a = { name = "public-1a-natgw", subnet = "public-1a", local_tags = { "foo" = "bar" } }
}

vpn_gateways = {
  vmseries-vgw = {
    name            = "vmseries-vgw"
    vpc_attached    = true
    amazon_side_asn = "7224"
    local_tags = { "vgw_tag" = "whatever" }
  }
}

vpc_endpoints = {
  ec2-endpoint = {
    name                = "ec2-endpoint"
    service_name        = "com.amazonaws.us-east-1.ec2"
    vpc_endpoint_type   = "Interface"
    security_groups     = ["vpc-endpoint"]
    subnet_ids          = ["lambda-1a", "lambda-1b"]
    private_dns_enabled = false
    local_tags          = { "foo" = "bar" }
}

security_groups = {
  vpc-endpoint = {
    name       = "vpc-endpoint"
    local_tags = { "foo" = "bar" }
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
  }
}

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| nat\_gateways | Map of NAT Gateways to create | `any` | `{}` | no |
| prefix\_name\_tag | Prepended to name tags for various resources. Leave as empty string if not desired. | `string` | `""` | no |
| security\_groups | Map of Security Groups | `any` | `{}` | no |
| subnets | Map of Subnets to create | `any` | `{}` | no |
| vpc | Map of parameters for the VPC. | `any` | `{}` | no |
| vpc\_endpoints | Map of VPC endpoints | `any` | `{}` | no |
| vpc\_route\_tables | Map of VPC route Tables to create | `any` | `{}` | no |
| vpn\_gateways | Map of VGWs to create | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aws\_vpc\_endpoint\_interface\_ids | Interface VPC Endpoint Name -> ID Map (New) |
| internet\_gateway\_id | Internet Gateway Name -> ID Map (New) |
| nat\_gateway\_ids | NAT Gateway Name -> ID Map (New) |
| route\_table\_ids | Route Tables Name -> ID Map (New) |
| security\_group\_ids | Security Group Name -> ID Map (New) |
| subnet\_ids | Subnets Name -> ID Map (New AND Existing) |
| vpc\_id | VPC Name -> ID Map (New OR Existing) |
| vpn\_gateway\_ids | VPN Gateway Name -> ID Map (New) |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Nested Map Input Variable Definitions

For each of the nested map variables, the key of each map will be the terraform state resource identifier within terraform and must be unique, but is not used for resource naming.

### vpc

The vpc variable is a map of maps, where each map represents a vpc. Unlike the rest of the nested map vars for this module, the vpc variable is assumed for only a single VPC definition.

There is brownfield support for existing vpc, for this only required to specify `name` and `existing = true`.

The vpc map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new / existing VPC  | string | - | yes | yes |
| existing | Flag only if referencing an existing VPC  | bool | `"false"` | no | yes |
| cidr_block | The CIDR formatted IP range of the VPC being created | string | - | yes | no |
| secondary_cidr_block | List of additional CIDR ranges to asssoicate with VPC | list(string) | - | no | no |
| instance_tenancy | Tenancy option for instances. `"default"`, `"dedicated"`, or `"host"` | string | `"default"` | no | no |
| enable_dns_support | Enable DNS Support | bool | `"true"` | no | no |
| enable_dns_hostnames | Enable DNS hostnames | bool | `"false"` | no | no |
| internet_gateway | Enable IGW creation for this VPC  | bool | `"false"` | no | no |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | no |


### vpc_route_tables

The vpc_route_tables variable is a map of maps, where each map represents a route table.

There is no brownfield support yet for this resource type.

Each vpc_route_tables map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new route table | string | - | yes | n/a |
| igw_association | Name of internet gateway to associate for Ingress Routing (using terraform resource identifier key) | string | - | no | n/a |
| vgw_association | Name of vpn gateway to associate for Ingress Routing (using terraform resource identifier key) | string | - | no | n/a |
| vgw_propagation | Name of vpn gateway to enable propagation from (using terraform resource identifier key) | string | - | no | n/a |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | no |

### subnets

The subnets variable is a map of maps, where each map represents a subnet.

There is brownfield support for existing subnets, for this only required to specify `name` and `existing = true`.

Each subnet map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new / existing subnet  | string | - | yes | yes |
| existing | Flag only if referencing an existing subnet  | bool | `"false"` | no | yes |
| cidr | The CIDR formatted IP range of the subnet being created | string | - | yes | no |
| rt | The Route Table to associate the subnet with | string | - | yes | no |
| az | The availability zone for the subnet  | string | - | no | no |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | no |

### nat_gateways

The nat_gateways variable is a map of maps, where each map represents a nat_gateway. 

There is no brownfield support yet for this resource type.

Each nat_gateways map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new NAT Gateway to create | string | - | yes | n/a |
| subnet | Terraform resource name of the subnet to create NAT Gateway  | sring | - | yes | n/a |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | n/a |

### vpn_gateways

The vpn_gateways variable is a map of maps, where each map represents a vpn_gateway. 

There is no brownfield support yet for this resource type.

Each vpn_gateways map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new VPN Gateway to create | string | - | yes | n/a |
| amazon_side_asn | ASN for the VPN Gateway | string | - | yes | n/a |
| vpc_attached | Enable attachment to this VPC. Only one VPN gateway can be attached to VPC | bool | `"true"` | no | n/a |
| dx_gateway_id | ID of existing Direct Connect Gateway to associate VGW with | string | - | no | n/a |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | n/a |

### vpc_endpoints

The vpc_endpoints variable is a map of maps, where each map represents a vpc_endpoint. Supports both interface and gateway endpoint types. 

There is no brownfield support yet for this resource type.

Each vpc_endpoints map has the following inputs available (please see examples folder for additional references):

[Registry Information](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new VPC Endpoint to create | string | - | yes | n/a |
| service_name | AWS Service Name in format `com.amazonaws.<region>.<service>` | string | - | yes | n/a |
| vpc_endpoint_type | "Interface" or "Gateway" | string | - | yes | n/a |
| security_groups | "Interface" type only. List of security groups to associate (using terraform resource identifier key) | list(string) | - | yes (for "Interface" type) | n/a |
| subnet_ids | "Interface" type only. List of subnets to associate (using terraform resource identifier key) | list(string) | - | no | n/a |
| route_table_ids | "Gateway" type only. List of route tables to associate (using terraform resource identifier key) | list(string) | - | no | n/a |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | n/a |

### secrutiy_groups
