# Palo Alto Networks VPC Module for AWS

A Terraform module for deploying a VPC in AWS.

One advantage of this module over the [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
module is that it does not create multiple resources based on Terraform `count` iterator. This allows for example
[easier removal](https://github.com/PaloAltoNetworks/terraform-best-practices#22-looping) of any single subnet,
without the need to briefly destroy and re-create any other subnet.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name                    = var.name
  cidr_block              = var.vpc_cidr_block
  secondary_cidr_blocks   = var.vpc_secondary_cidr_blocks
  create_internet_gateway = true
  global_tags             = var.global_tags
  vpc_tags                = var.vpc_tags
  security_groups         = var.security_groups
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.29, < 1.1 |
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
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | n/a | `bool` | `true` | no |
| <a name="input_create_vpn_gateway"></a> [create\_vpn\_gateway](#input\_create\_vpn\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | n/a | `any` | `null` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | n/a | `any` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Optional map of arbitrary tags to apply to all the created resources. | `map(string)` | `{}` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | n/a | `any` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `any` | `null` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | n/a | `list` | `[]` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | The `security_groups` variable is a map of maps, where each map represents an AWS Security Group.<br>  The key of each entry acts as the Security Group name.<br>  List of available attributes of each Security Group entry:<br>  - `rules`: A list of objects representing a Security Group rule. The key of each entry acts as the name of the rule and<br>      needs to be unique across all rules in the Security Group.<br>      List of attributes available to define a Security Group rule:<br>      - `description`: Security Group description.<br>      - `type`: Specifies if rule will be evaluated on ingress (inbound) or egress (outbound) traffic.<br>      - `cidr_blocks`: List of CIDR blocks - for ingress, determines the traffic that can reach your instance. For egress<br>      Determines the traffic that can leave your instance, and where it can go.<br><br><br>  Example:<pre>security_groups = {<br>    vmseries-mgmt = {<br>      name = "vmseries-mgmt"<br>      rules = {<br>        all-outbound = {<br>          description = "Permit All traffic outbound"<br>          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>        https-inbound-private = {<br>          description = "Permit HTTPS for VM-Series Management"<br>          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"<br>          cidr_blocks = ["10.0.0.0/8"]<br>        }<br>        https-inbound-eip = {<br>          description = "Permit HTTPS for VM-Series Management from known public IPs"<br>          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"<br>          cidr_blocks = ["100.100.100.100/32"]<br>        }<br>        ssh-inbound-eip = {<br>          description = "Permit SSH for VM-Series Management from known public IPs"<br>          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"<br>          cidr_blocks = ["100.100.100.100/32"]<br>        }<br>      }<br>    }<br>  }</pre> | `any` | `{}` | no |
| <a name="input_use_internet_gateway"></a> [use\_internet\_gateway](#input\_use\_internet\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | n/a | `map` | `{}` | no |
| <a name="input_vpn_gateway_amazon_side_asn"></a> [vpn\_gateway\_amazon\_side\_asn](#input\_vpn\_gateway\_amazon\_side\_asn) | n/a | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The VPC identifier (either created or pre-existing). |
| <a name="output_igw_as_next_hop_set"></a> [igw\_as\_next\_hop\_set](#output\_igw\_as\_next\_hop\_set) | The object is suitable for use as `vpc_route` module's input `next_hop_set`. |
| <a name="output_internet_gateway"></a> [internet\_gateway](#output\_internet\_gateway) | The entire Internet Gateway object. It is null when `create_internet_gateway` is false. |
| <a name="output_internet_gateway_route_table"></a> [internet\_gateway\_route\_table](#output\_internet\_gateway\_route\_table) | The Route Table object created to handle traffic from Internet Gateway (IGW). It is null when `create_internet_gateway` is false. |
| <a name="output_name"></a> [name](#output\_name) | The VPC Name Tag (either created or pre-existing). |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Map of Security Group Name -> ID (newly created). |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | The entire VPC object (either created or pre-existing). |
| <a name="output_vpn_gateway"></a> [vpn\_gateway](#output\_vpn\_gateway) | The entire Virtual Private Gateway object. It is null when `create_vpn_gateway` is false. |
| <a name="output_vpn_gateway_route_table"></a> [vpn\_gateway\_route\_table](#output\_vpn\_gateway\_route\_table) | The Route Table object created to handle traffic from Virtual Private Gateway (VGW). It is null when `create_vpn_gateway` is false. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
