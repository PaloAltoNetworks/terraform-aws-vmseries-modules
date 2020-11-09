# VPC module for VM-Series

## Overview  

Module for interactions with Transit Gateways for VM-Series deployments.


### Usage

See examples for more details of usage.

`main.tf`

```
locals {
  vpcs = {
    "foo" = "vpc-123456789012"
    "bar" = "vpc-123456789012"
  }
  subnets = {
    "foo" = "subnet-123456789012"
    "bar" = "subnet-123456789012"
    "baz" = "subnet-123456789012"
  }
}

module "transit_gateways" {
  source                          = "../../"
  global_tags                     = var.global_tags
  prefix_name_tag                 = var.prefix_name_tag
  subnets                         = local.subnets
  vpcs                            = local.vpcs
  transit_gateways                = var.transit_gateways
  transit_gateway_vpc_attachments = var.transit_gateway_vpc_attachments
  transit_gateway_peerings        = var.transit_gateway_peerings
}
```

`terraform.tfvars`

```
region = "us-east-1"

prefix_name_tag = "tgw-module-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

transit_gateways = {
  prod = {
    name              = "prod"
    local_tags        = { "foo" = "bar" }
    asn               = "65301",
    shared_principals = ["123456789012"]
    route_tables = {
      security = { name = "security-in", local_tags = { "foo" = "bar" } },
      spoke    = { name = "spoke-in" }
    }
  },
  existing = { // Example of brownfield support for existing TGW and TGW route table
    name     = "foo"
    existing = true
    route_tables = {
      security = { name = "bar", existing = true },
    }
  }
}

transit_gateway_vpc_attachments = {
  prod = {
    name                                    = "prod-security"
    local_tags                              = { "foo" = "bar" }
    vpc                                     = "foo"
    subnets                                 = ["foo", "bar"]
    transit_gateway                         = "prod"
    transit_gateway_route_table_association = "security"
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

| Name | Version |
|------|---------|
| terraform | >=0.12.29, <0.14 |
| aws | ~> 3.10 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.10 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region for provider | `string` | `""` | no |
| prefix\_name\_tag | Prepended to name tags for various resources. Leave as empty string if not desired. | `string` | `""` | no |
| global\_tags | Optional Map of arbitrary tags to apply to all resources | `map(any)` | `{}` | no |
| vpcs | Map of Existing VPC Names to IDs. Used for TGW attachments. | `any` | `{}` | no |
| subnets | Map of Existing Subnet Names to IDs. Used for TGW attachments. | `any` | `{}` | no |
| transit\_gateways | Nested Map of TGWs and their attributes (Brownfield Supported) | `any` | `{}` | no |
| transit\_gateway\_vpc\_attachments | Map of attachments to create and RT to associate / propagate to | `map(any)` | `{}` | no |
| transit\_gateway\_peerings | Map of parameters to peer TGWs with cross-region / cross-account existing TGW | `map(any)` | `{}` | no |
| transit\_gateway\_peer\_region | Region for alias provider for Transit Gateway Peering | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| transit\_gateway\_ids | TGW Name -> ID Map (New AND Existing) |
| transit\_gateway\_route\_table\_ids | TGW Route Table Name -> ID Map (New AND Existing) |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Variables for existing resource ID mappings

For resources that are referenced by this sub-module but assumed to be created elsewhere, a map of name -> ID mappings are passed to this module.

The names are referenced in the map variables for the transit gateway resources and a lookup is performed inside of this module to find the associated ID.

This map would typically be passed in from the outputs of the vpc sub-module in this project. Otherwise, these can be defined manually, from data sources, or from any other state output in the correct format.

### vpcs

The vpcs variable is a map of existing vpc names -> IDs used for creating VPC attachments to the transit gateways in this module. 


```
  vpcs = {
    "foo" = "vpc-123456789012"
    "bar" = "vpc-123456789012"
  }
```

### subnets

The subnets variable is a map of existing subnet names -> IDs used for creating VPC attachments to the transit gateways in this module.


```
  subnets = {
    "foo" = "subnet-123456789012"
    "bar" = "subnet-123456789012"
    "baz" = "subnet-123456789012"
  }
```

## Nested Map Input Variable Definitions

### transit\_gateways

The transit_gateways variable is a map of maps, where each map represents a transit gateway, the route tables associated to each transit gateway, and other attributes.

There is brownfield support for existing transit gateways and existing transit gateway route tables.

Each transit_gateways map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the transit gateway | string | - | yes | yes |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | no |
| existing | Flag only if referencing an existing transit gateway  | bool | `"false"` | no | yes |
| asn  | ASN Number for the transit gateway  | string | - | no | no |
| shared_principals | List of account IDs to share this transit gateway with | list(string) | - | no | no |
| route_tables | Map of route tables associated with this transit gateway (see below) | map | - | no | no |

#### transit\_gateways route\_tables \{\}

Nested map within each transit_gateway definition to define the route tables of each transit gateway.

There is brownfield support for existing transit gateway route tables.

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the transit gateway | string | - | yes | yes |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | no |
| existing | Flag only if referencing an existing transit gateway route table | bool | `"false"` | no | yes |

### transit\_gateway\_vpc\_attachments