# Transit Gateway module for VM-Series

A Terraform module for deploying AWS Transit Gateways. The module does not use default route tables by design - specify all the route
tables explicitly through respective input variables.

>A transit gateway is a network transit hub that you can use to interconnect your virtual private clouds (VPCs) and on-premises networks. As your cloud infrastructure expands globally, inter-Region peering connects transit gateways together using the AWS Global Infrastructure.

## Usage

For example usage, please refer to the [Examples](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/examples) directory.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ram_principal_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_ec2_transit_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |
| [aws_ec2_transit_gateway_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway_route_table) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asn"></a> [asn](#input\_asn) | BGP Autonomous System Number of the AWS Transit Gateway. | `number` | `65200` | no |
| <a name="input_auto_accept_shared_attachments"></a> [auto\_accept\_shared\_attachments](#input\_auto\_accept\_shared\_attachments) | See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway). | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | n/a | `bool` | `true` | no |
| <a name="input_dns_support"></a> [dns\_support](#input\_dns\_support) | See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway). | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name tag for the Transit Gateway and associated resources. | `string` | n/a | yes |
| <a name="input_ram_resource_share_name"></a> [ram\_resource\_share\_name](#input\_ram\_resource\_share\_name) | n/a | `any` | `null` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | n/a | `map` | `{}` | no |
| <a name="input_shared_principals"></a> [shared\_principals](#input\_shared\_principals) | n/a | `map` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional Map of arbitrary tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpn_ecmp_support"></a> [vpn\_ecmp\_support](#input\_vpn\_ecmp\_support) | See the [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway). | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | Same as the input `name`. |
| <a name="output_route_tables"></a> [route\_tables](#output\_route\_tables) | n/a |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | The entire object `aws_ec2_transit_gateway`. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
