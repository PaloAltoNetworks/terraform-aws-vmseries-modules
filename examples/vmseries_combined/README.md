# VM-Series in the Centralized Design Combined Inbound Architecture

Deployment of Palo Alto Networks VM-Series into a variation on one of its [Reference Architectures](https://pandocs.tech/fw/110p-prime): the *Centralized* design using *Combined Inbound Security*.

In a nutshell it means:

- Multiple Application VPCs can be secured using a single Security VPC.
- The outbound dataplane traffic traverses the transit gateway (TGW) and the gateway load balancer (GWLB).
- The outbound dataplane traffic traverses a _single_ interface per each VM-Series, so it is in intrazone category
  instead of interzone. There is no overlay routing on VM-Series. This is a slight departure from the Reference Architecture.
  (It is called a one-arm mode in AWS docs.)
- The inbound dataplane traffic _does not_ traverse TGW and only traverses GWLB. It is also intrazone, in the same manner
  as the outbound traffic.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 3.50 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 3.50 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app1_ec2"></a> [app1\_ec2](#module\_app1\_ec2) | terraform-aws-modules/ec2-instance/aws | 2.19.0 |
| <a name="module_app1_gwlbe_inbound"></a> [app1\_gwlbe\_inbound](#module\_app1\_gwlbe\_inbound) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_app1_lb"></a> [app1\_lb](#module\_app1\_lb) | terraform-aws-modules/alb/aws | ~> 6.5 |
| <a name="module_app1_route"></a> [app1\_route](#module\_app1\_route) | ../../modules/vpc_route | n/a |
| <a name="module_app1_subnet_sets"></a> [app1\_subnet\_sets](#module\_app1\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_app1_transit_gateway_attachment"></a> [app1\_transit\_gateway\_attachment](#module\_app1\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_app1_vpc"></a> [app1\_vpc](#module\_app1\_vpc) | ../../modules/vpc | n/a |
| <a name="module_bootstrap"></a> [bootstrap](#module\_bootstrap) | ../../modules/bootstrap | n/a |
| <a name="module_gwlbe_eastwest"></a> [gwlbe\_eastwest](#module\_gwlbe\_eastwest) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_gwlbe_outbound"></a> [gwlbe\_outbound](#module\_gwlbe\_outbound) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_security_gwlb"></a> [security\_gwlb](#module\_security\_gwlb) | ../../modules/gwlb | n/a |
| <a name="module_security_subnet_sets"></a> [security\_subnet\_sets](#module\_security\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_security_transit_gateway_attachment"></a> [security\_transit\_gateway\_attachment](#module\_security\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_security_vpc"></a> [security\_vpc](#module\_security\_vpc) | ../../modules/vpc | n/a |
| <a name="module_security_vpc_routes"></a> [security\_vpc\_routes](#module\_security\_vpc\_routes) | ../../modules/vpc_route | n/a |
| <a name="module_transit_gateway"></a> [transit\_gateway](#module\_transit\_gateway) | ../../modules/transit_gateway | n/a |
| <a name="module_vmseries"></a> [vmseries](#module\_vmseries) | ../../modules/vmseries | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_route.from_spokes_to_security](https://registry.terraform.io/providers/hashicorp/aws/3.50/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_eip.lb](https://registry.terraform.io/providers/hashicorp/aws/3.50/docs/resources/eip) | resource |
| [aws_key_pair.this](https://registry.terraform.io/providers/hashicorp/aws/3.50/docs/resources/key_pair) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/3.50/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app1_gwlb_endpoint_set_name"></a> [app1\_gwlb\_endpoint\_set\_name](#input\_app1\_gwlb\_endpoint\_set\_name) | n/a | `any` | n/a | yes |
| <a name="input_app1_transit_gateway_attachment_name"></a> [app1\_transit\_gateway\_attachment\_name](#input\_app1\_transit\_gateway\_attachment\_name) | n/a | `any` | n/a | yes |
| <a name="input_app1_vpc_cidr"></a> [app1\_vpc\_cidr](#input\_app1\_vpc\_cidr) | n/a | `any` | n/a | yes |
| <a name="input_app1_vpc_name"></a> [app1\_vpc\_name](#input\_app1\_vpc\_name) | n/a | `any` | n/a | yes |
| <a name="input_app1_vpc_security_groups"></a> [app1\_vpc\_security\_groups](#input\_app1\_vpc\_security\_groups) | n/a | `any` | n/a | yes |
| <a name="input_app1_vpc_subnets"></a> [app1\_vpc\_subnets](#input\_app1\_vpc\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details. | `string` | `null` | no |
| <a name="input_aws_assume_role"></a> [aws\_assume\_role](#input\_aws\_assume\_role) | Example:<pre>aws_assume_role = {<br>  role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"<br>  session_name = "SESSION_NAME"<br>  external_id  = "EXTERNAL_ID"<br>}</pre> | `map(string)` | `null` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Which profile name to use from within the `aws_shared_credentials_file`. Example: "myprofile". See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details. | `string` | `null` | no |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details. | `string` | `null` | no |
| <a name="input_aws_shared_credentials_file"></a> [aws\_shared\_credentials\_file](#input\_aws\_shared\_credentials\_file) | Example: "/Users/tf\_user/.aws/creds". See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details. | `string` | `null` | no |
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | n/a | `bool` | `true` | no |
| <a name="input_existing_gwlb_name"></a> [existing\_gwlb\_name](#input\_existing\_gwlb\_name) | n/a | `any` | n/a | yes |
| <a name="input_firewalls"></a> [firewalls](#input\_firewalls) | n/a | `any` | n/a | yes |
| <a name="input_fw_instance_type"></a> [fw\_instance\_type](#input\_fw\_instance\_type) | n/a | `any` | n/a | yes |
| <a name="input_fw_license_type"></a> [fw\_license\_type](#input\_fw\_license\_type) | n/a | `any` | n/a | yes |
| <a name="input_fw_version"></a> [fw\_version](#input\_fw\_version) | n/a | `any` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_endpoint_set_eastwest_name"></a> [gwlb\_endpoint\_set\_eastwest\_name](#input\_gwlb\_endpoint\_set\_eastwest\_name) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_endpoint_set_outbound_name"></a> [gwlb\_endpoint\_set\_outbound\_name](#input\_gwlb\_endpoint\_set\_outbound\_name) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_name"></a> [gwlb\_name](#input\_gwlb\_name) | n/a | `any` | n/a | yes |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | n/a | `any` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | n/a | `any` | n/a | yes |
| <a name="input_prefix_name_tag"></a> [prefix\_name\_tag](#input\_prefix\_name\_tag) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `any` | n/a | yes |
| <a name="input_security_transit_gateway_attachment_name"></a> [security\_transit\_gateway\_attachment\_name](#input\_security\_transit\_gateway\_attachment\_name) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_cidr"></a> [security\_vpc\_cidr](#input\_security\_vpc\_cidr) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_mgmt_routes_to_tgw"></a> [security\_vpc\_mgmt\_routes\_to\_tgw](#input\_security\_vpc\_mgmt\_routes\_to\_tgw) | The eastwest inspection of traffic heading to VM-Series mgmt is not possible. Due to AWS own limitations, anything from tgw destined for mgmt could *not* possibly override LocalVPC route. Henceforth no mgmt routes go back to gwlbe\_eastwest. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_name"></a> [security\_vpc\_name](#input\_security\_vpc\_name) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_routes_eastwest_cidrs"></a> [security\_vpc\_routes\_eastwest\_cidrs](#input\_security\_vpc\_routes\_eastwest\_cidrs) | From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing back to TGW. A list of strings, for example `["10.0.0.0/8"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_destin_cidrs"></a> [security\_vpc\_routes\_outbound\_destin\_cidrs](#input\_security\_vpc\_routes\_outbound\_destin\_cidrs) | From the perspective of Security VPC, the destination addresses of packets coming from TGW and flowing outside. A list of strings, for example `["0.0.0.0/0"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_source_cidrs"></a> [security\_vpc\_routes\_outbound\_source\_cidrs](#input\_security\_vpc\_routes\_outbound\_source\_cidrs) | From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing outside. Used for return traffic routes post-inspection. A list of strings, for example `["10.0.0.0/8"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_security_groups"></a> [security\_vpc\_security\_groups](#input\_security\_vpc\_security\_groups) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_subnets"></a> [security\_vpc\_subnets](#input\_security\_vpc\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | n/a | `string` | `"sshkey"` | no |
| <a name="input_ssh_public_key_file_path"></a> [ssh\_public\_key\_file\_path](#input\_ssh\_public\_key\_file\_path) | n/a | `any` | n/a | yes |
| <a name="input_transit_gateway_asn"></a> [transit\_gateway\_asn](#input\_transit\_gateway\_asn) | n/a | `any` | n/a | yes |
| <a name="input_transit_gateway_name"></a> [transit\_gateway\_name](#input\_transit\_gateway\_name) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app1_inspected_dns_name"></a> [app1\_inspected\_dns\_name](#output\_app1\_inspected\_dns\_name) | The DNS name that you can use to SSH into a testbox. Use `ssh ubuntu@<<value>>` command with the same public key as given in the `ssh_public_key_file_path` input. |
| <a name="output_app1_inspected_public_ip"></a> [app1\_inspected\_public\_ip](#output\_app1\_inspected\_public\_ip) | The IP address behind the `app1_inspected_dns_name`. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
