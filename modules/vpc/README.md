# VPC Terraform Module for AWS

## Overview

Module for a single VPC and associated networking infrastructure resources.

One advantage of this module over the [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
module is that it does not create multiple resources based on Terraform `count` iterator. This allows for example
[easier removal](https://github.com/PaloAltoNetworks/terraform-best-practices#22-looping) of any single subnet,
without the need to briefly destroy and re-create any other subnet.

### Usage

See the examples for details of usage.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.29, < 0.16 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route_table.from_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.from_vgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.from_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.from_vgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_ipv4_cidr_block_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_generated_ipv6_cidr_block"></a> [assign\_generated\_ipv6\_cidr\_block](#input\_assign\_generated\_ipv6\_cidr\_block) | n/a | `any` | `null` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | n/a | `any` | `null` | no |
| <a name="input_create_internet_gateway"></a> [create\_internet\_gateway](#input\_create\_internet\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | n/a | `bool` | `true` | no |
| <a name="input_create_vpn_gateway"></a> [create\_vpn\_gateway](#input\_create\_vpn\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | n/a | `any` | `null` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | n/a | `any` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Optional map of arbitrary tags to apply to all the created resources. | `map(string)` | `{}` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | n/a | `any` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `any` | `null` | no |
| <a name="input_prefix_name_tag"></a> [prefix\_name\_tag](#input\_prefix\_name\_tag) | Prepend a string to Name tags for the created resources. Can be empty. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region for deployment, for example "us-east-1". | `string` | `""` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | n/a | `list` | `[]` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Map of AWS Security Groups. | `any` | `{}` | no |
| <a name="input_use_internet_gateway"></a> [use\_internet\_gateway](#input\_use\_internet\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | n/a | `map` | `{}` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | n/a | `map` | `{}` | no |
| <a name="input_vpn_gateway_amazon_side_asn"></a> [vpn\_gateway\_amazon\_side\_asn](#input\_vpn\_gateway\_amazon\_side\_asn) | n/a | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dep"></a> [dep](#output\_dep) | n/a |
| <a name="output_id"></a> [id](#output\_id) | The VPC identifier (either created or pre-existing). |
| <a name="output_igw_as_next_hop_set"></a> [igw\_as\_next\_hop\_set](#output\_igw\_as\_next\_hop\_set) | The object is suitable for use as `vpc_route` module's input `next_hop_set`. |
| <a name="output_internet_gateway"></a> [internet\_gateway](#output\_internet\_gateway) | The entire Internet Gateway object. It is null when `create_internet_gateway` is false. |
| <a name="output_internet_gateway_route_table"></a> [internet\_gateway\_route\_table](#output\_internet\_gateway\_route\_table) | The Route Table object created to handle traffic from Internet Gateway (IGW). It is null when `create_internet_gateway` is false. |
| <a name="output_name"></a> [name](#output\_name) | The VPC Name Tag (either created or pre-existing). |
| <a name="output_routing_cidrs"></a> [routing\_cidrs](#output\_routing\_cidrs) | n/a |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Map of Security Group Name -> ID (newly created). |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | The entire VPC object (either created or pre-existing). |
| <a name="output_vpn_gateway"></a> [vpn\_gateway](#output\_vpn\_gateway) | The entire Virtual Private Gateway object. It is null when `create_vpn_gateway` is false. |
| <a name="output_vpn_gateway_route_table"></a> [vpn\_gateway\_route\_table](#output\_vpn\_gateway\_route\_table) | The Route Table object created to handle traffic from Virtual Private Gateway (VGW). It is null when `create_vpn_gateway` is false. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Nested Map Input Variable Definitions

For each of the nested map variables, the key of each map will be the terraform state resource identifier within terraform and must be unique, but is not used for resource naming.

### vpc_endpoints

The `vpc_endpoints` variable is a map of maps, where each map represents a VPC Endpoint. Supports both interface and gateway endpoint types.

There is no brownfield support yet for this resource type.

Each vpc_endpoints map has the following inputs available (please see examples folder for additional references):

[Provider's manual](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) for the `aws_vpc_endpoint` resource.

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new VPC Endpoint to create | string | - | yes | n/a |
| service_name | AWS Service Name in format `com.amazonaws.<region>.<service>` | string | - | yes | n/a |
| vpc_endpoint_type | "Interface" or "Gateway" | string | - | yes | n/a |
| security_groups | "Interface" type only. List of security groups to associate (using terraform resource identifier key) | list(string) | - | yes (for "Interface" type) | n/a |
| subnet_ids | "Interface" type only. List of subnets to associate (using terraform resource identifier key) | list(string) | - | no | n/a |
| route_table_ids | "Gateway" type only. List of route tables to associate (using terraform resource identifier key) | list(string) | - | no | n/a |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | n/a |

### security_groups

The `security_groups` variable is a map of maps, where each map represents an AWS Security Group.
