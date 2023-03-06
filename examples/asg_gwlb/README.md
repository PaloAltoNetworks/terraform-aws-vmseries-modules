# ASG GWLB

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.25 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.25 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app1_gwlbe_inbound"></a> [app1\_gwlbe\_inbound](#module\_app1\_gwlbe\_inbound) | PaloAltoNetworks/vmseries-modules/aws//modules/gwlb_endpoint_set | 0.4.1 |
| <a name="module_app1_lb"></a> [app1\_lb](#module\_app1\_lb) | PaloAltoNetworks/vmseries-modules/aws//modules/nlb | 0.4.1 |
| <a name="module_app1_route"></a> [app1\_route](#module\_app1\_route) | PaloAltoNetworks/vmseries-modules/aws//modules/vpc_route | 0.4.1 |
| <a name="module_app1_subnet_sets"></a> [app1\_subnet\_sets](#module\_app1\_subnet\_sets) | PaloAltoNetworks/vmseries-modules/aws//modules/subnet_set | 0.4.1 |
| <a name="module_app1_transit_gateway_attachment"></a> [app1\_transit\_gateway\_attachment](#module\_app1\_transit\_gateway\_attachment) | PaloAltoNetworks/vmseries-modules/aws//modules/transit_gateway_attachment | 0.4.1 |
| <a name="module_app1_vpc"></a> [app1\_vpc](#module\_app1\_vpc) | PaloAltoNetworks/vmseries-modules/aws//modules/vpc | 0.4.1 |
| <a name="module_gwlbe_eastwest"></a> [gwlbe\_eastwest](#module\_gwlbe\_eastwest) | PaloAltoNetworks/vmseries-modules/aws//modules/gwlb_endpoint_set | 0.4.1 |
| <a name="module_gwlbe_outbound"></a> [gwlbe\_outbound](#module\_gwlbe\_outbound) | PaloAltoNetworks/vmseries-modules/aws//modules/gwlb_endpoint_set | 0.4.1 |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | PaloAltoNetworks/vmseries-modules/aws//modules/nat_gateway_set | 0.4.1 |
| <a name="module_security_gwlb"></a> [security\_gwlb](#module\_security\_gwlb) | PaloAltoNetworks/vmseries-modules/aws//modules/gwlb | 0.4.1 |
| <a name="module_security_subnet_sets"></a> [security\_subnet\_sets](#module\_security\_subnet\_sets) | PaloAltoNetworks/vmseries-modules/aws//modules/subnet_set | 0.4.1 |
| <a name="module_security_transit_gateway_attachment"></a> [security\_transit\_gateway\_attachment](#module\_security\_transit\_gateway\_attachment) | PaloAltoNetworks/vmseries-modules/aws//modules/transit_gateway_attachment | 0.4.1 |
| <a name="module_security_vpc"></a> [security\_vpc](#module\_security\_vpc) | PaloAltoNetworks/vmseries-modules/aws//modules/vpc | 0.4.1 |
| <a name="module_security_vpc_routes"></a> [security\_vpc\_routes](#module\_security\_vpc\_routes) | PaloAltoNetworks/vmseries-modules/aws//modules/vpc_route | 0.4.1 |
| <a name="module_transit_gateway"></a> [transit\_gateway](#module\_transit\_gateway) | PaloAltoNetworks/vmseries-modules/aws//modules/transit_gateway | 0.4.1 |
| <a name="module_vm_series_asg"></a> [vm\_series\_asg](#module\_vm\_series\_asg) | ..//..//deployment/modules/asg | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_route.from_security_to_panorama](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.from_spokes_to_security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_iam_instance_profile.vm_series_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.vm_series_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vm_series_ec2_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.app1_vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app1_gwlb_endpoint_set_name"></a> [app1\_gwlb\_endpoint\_set\_name](#input\_app1\_gwlb\_endpoint\_set\_name) | The name of the GWLB VPC Endpoint created to inspect traffic inbound from Internet to the App1 load balancer. | `string` | n/a | yes |
| <a name="input_app1_transit_gateway_attachment_name"></a> [app1\_transit\_gateway\_attachment\_name](#input\_app1\_transit\_gateway\_attachment\_name) | The name of the TGW Attachment to be created inside the App1 VPC. | `string` | n/a | yes |
| <a name="input_app1_vm_type"></a> [app1\_vm\_type](#input\_app1\_vm\_type) | EC2 type for "app1" VMs. | `string` | `"t2.micro"` | no |
| <a name="input_app1_vms"></a> [app1\_vms](#input\_app1\_vms) | Definition of an example "app1" application VMs. They are based on the latest version of Bitnami's NGINX image.<br>The structure of this map is similar to the one defining VM-Series, only one property is supported though: the Availability Zone the VM should be placed in.<br>Example:<pre>app_vms = {<br>  "appvm01" = { az = "us-east-1b" }<br>  "appvm02" = { az = "us-east-1a" }<br>}</pre> | `map(any)` | n/a | yes |
| <a name="input_app1_vpc_cidr"></a> [app1\_vpc\_cidr](#input\_app1\_vpc\_cidr) | The primary IPv4 CIDR of the created App1 VPC. | `string` | n/a | yes |
| <a name="input_app1_vpc_name"></a> [app1\_vpc\_name](#input\_app1\_vpc\_name) | The name tag of the created App1 VPC. | `string` | n/a | yes |
| <a name="input_app1_vpc_security_groups"></a> [app1\_vpc\_security\_groups](#input\_app1\_vpc\_security\_groups) | n/a | `any` | n/a | yes |
| <a name="input_app1_vpc_subnets"></a> [app1\_vpc\_subnets](#input\_app1\_vpc\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_asg_desired_cap"></a> [asg\_desired\_cap](#input\_asg\_desired\_cap) | n/a | `any` | n/a | yes |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | n/a | `any` | n/a | yes |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | n/a | `any` | n/a | yes |
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | n/a | `bool` | `false` | no |
| <a name="input_delicense_ssm_param_name"></a> [delicense\_ssm\_param\_name](#input\_delicense\_ssm\_param\_name) | n/a | `any` | n/a | yes |
| <a name="input_ebs_kms_id"></a> [ebs\_kms\_id](#input\_ebs\_kms\_id) | n/a | `any` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_endpoint_set_eastwest_name"></a> [gwlb\_endpoint\_set\_eastwest\_name](#input\_gwlb\_endpoint\_set\_eastwest\_name) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_endpoint_set_outbound_name"></a> [gwlb\_endpoint\_set\_outbound\_name](#input\_gwlb\_endpoint\_set\_outbound\_name) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_name"></a> [gwlb\_name](#input\_gwlb\_name) | n/a | `any` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | ## General | `any` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | n/a | `any` | n/a | yes |
| <a name="input_panorama_transit_gateway_attachment_id"></a> [panorama\_transit\_gateway\_attachment\_id](#input\_panorama\_transit\_gateway\_attachment\_id) | n/a | `any` | n/a | yes |
| <a name="input_panorama_vpc_cidr"></a> [panorama\_vpc\_cidr](#input\_panorama\_vpc\_cidr) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | ## AWS Provider Authentication and Attributes | `any` | n/a | yes |
| <a name="input_scaling_cloudwatch_namespace"></a> [scaling\_cloudwatch\_namespace](#input\_scaling\_cloudwatch\_namespace) | n/a | `any` | n/a | yes |
| <a name="input_scaling_metric_name"></a> [scaling\_metric\_name](#input\_scaling\_metric\_name) | n/a | `any` | n/a | yes |
| <a name="input_scaling_plan_enabled"></a> [scaling\_plan\_enabled](#input\_scaling\_plan\_enabled) | n/a | `any` | n/a | yes |
| <a name="input_scaling_tags"></a> [scaling\_tags](#input\_scaling\_tags) | n/a | `any` | n/a | yes |
| <a name="input_scaling_target_value"></a> [scaling\_target\_value](#input\_scaling\_target\_value) | n/a | `any` | n/a | yes |
| <a name="input_security_gwlb_service_name"></a> [security\_gwlb\_service\_name](#input\_security\_gwlb\_service\_name) | Optional Service Name of the pre-existing GWLB which should receive traffic from `app1_gwlb_endpoint_set_name`.<br>If empty or null, instead use the Service Name of the default GWLB named `gwlb_name`.<br>Example: "com.amazonaws.vpce.us-west-2.vpce-svc-0123". | `string` | `""` | no |
| <a name="input_security_vpc_cidr"></a> [security\_vpc\_cidr](#input\_security\_vpc\_cidr) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_mgmt_routes_to_tgw"></a> [security\_vpc\_mgmt\_routes\_to\_tgw](#input\_security\_vpc\_mgmt\_routes\_to\_tgw) | The eastwest inspection of traffic heading to VM-Series management interface is not possible. <br>Due to AWS own limitations, anything from the TGW destined for the management interface could *not* possibly override LocalVPC route. <br>Henceforth no management routes go back to gwlbe\_eastwest. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_name"></a> [security\_vpc\_name](#input\_security\_vpc\_name) | ## Security VPC | `any` | n/a | yes |
| <a name="input_security_vpc_routes_eastwest_cidrs"></a> [security\_vpc\_routes\_eastwest\_cidrs](#input\_security\_vpc\_routes\_eastwest\_cidrs) | From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing back to TGW. <br>A list of strings, for example `[\"10.0.0.0/8\"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_destin_cidrs"></a> [security\_vpc\_routes\_outbound\_destin\_cidrs](#input\_security\_vpc\_routes\_outbound\_destin\_cidrs) | From the perspective of Security VPC, the destination addresses of packets coming from TGW and flowing outside. <br>A list of strings, for example `[\"0.0.0.0/0\"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_source_cidrs"></a> [security\_vpc\_routes\_outbound\_source\_cidrs](#input\_security\_vpc\_routes\_outbound\_source\_cidrs) | From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing outside.<br>Used for return traffic routes post-inspection. <br>A list of strings, for example `[\"10.0.0.0/8\"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_security_groups"></a> [security\_vpc\_security\_groups](#input\_security\_vpc\_security\_groups) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_subnets"></a> [security\_vpc\_subnets](#input\_security\_vpc\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_tgw_attachment_name"></a> [security\_vpc\_tgw\_attachment\_name](#input\_security\_vpc\_tgw\_attachment\_name) | n/a | `any` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | n/a | `any` | n/a | yes |
| <a name="input_ssh_public_key_file"></a> [ssh\_public\_key\_file](#input\_ssh\_public\_key\_file) | n/a | `any` | `null` | no |
| <a name="input_transit_gateway_asn"></a> [transit\_gateway\_asn](#input\_transit\_gateway\_asn) | Private Autonomous System Number (ASN) of the Transit Gateway for the Amazon side of a BGP session.<br>The range is 64512 to 65534 for 16-bit ASNs and 4200000000 to 4294967294 for 32-bit ASNs. | `number` | n/a | yes |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the created Transit Gateway. | `string` | n/a | yes |
| <a name="input_transit_gateway_name"></a> [transit\_gateway\_name](#input\_transit\_gateway\_name) | The name tag of the created Transit Gateway. | `string` | n/a | yes |
| <a name="input_transit_gateway_route_tables"></a> [transit\_gateway\_route\_tables](#input\_transit\_gateway\_route\_tables) | Complex input with the Route Tables of the Transit Gateway. Example:<pre>{<br>  "from_security_vpc" = {<br>    create = true<br>    name   = "myrt1"<br>  }<br>  "from_spoke_vpc" = {<br>    create = true<br>    name   = "myrt2"<br>  }<br>}</pre>Two keys are required:<br><br>- from\_security\_vpc describes which route table routes the traffic coming from the Security VPC,<br>- from\_spoke\_vpc describes which route table routes the traffic coming from the Spoke (App1) VPC.<br><br>Each of these entries can specify `create = true` which creates a new RT with a `name`.<br>With `create = false` the pre-existing RT named `name` is used. | `any` | n/a | yes |
| <a name="input_vmseries"></a> [vmseries](#input\_vmseries) | ## VM-Series | `any` | n/a | yes |
| <a name="input_vmseries_common"></a> [vmseries\_common](#input\_vmseries\_common) | n/a | `any` | n/a | yes |
| <a name="input_vmseries_interfaces"></a> [vmseries\_interfaces](#input\_vmseries\_interfaces) | n/a | `any` | n/a | yes |
| <a name="input_vmseries_version"></a> [vmseries\_version](#input\_vmseries\_version) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app1_inspected_dns_name"></a> [app1\_inspected\_dns\_name](#output\_app1\_inspected\_dns\_name) | FQDN of "app1" Internal Load Balancer.<br>Can be used in VM-Series configuration to balance traffic between the application instances. |
| <a name="output_security_gwlb_service_name"></a> [security\_gwlb\_service\_name](#output\_security\_gwlb\_service\_name) | The AWS Service Name of the created GWLB, which is suitable to use for subsequent VPC Endpoints. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
