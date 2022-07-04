## Info
Initial Panorama setup takes a few minutes to complete.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.75.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_panorama"></a> [panorama](#module\_panorama) | ../../modules/panorama | n/a |
| <a name="module_security_subnet_sets"></a> [security\_subnet\_sets](#module\_security\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_security_vpc"></a> [security\_vpc](#module\_security\_vpc) | ../../modules/vpc | n/a |
| <a name="module_security_vpc_routes"></a> [security\_vpc\_routes](#module\_security\_vpc\_routes) | ../../modules/vpc_route | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.panorama_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy_attachment.panorama_iam_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.panorama_read_only_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_iam_policy.iam_policy_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_kms_alias.current_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to assign to the resources.<br>If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level." | `map(any)` | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix use for creating unique names. | `string` | `""` | no |
| <a name="input_panorama_az"></a> [panorama\_az](#input\_panorama\_az) | Availability zone where Panorama was be deployed. | `string` | n/a | yes |
| <a name="input_panorama_create_iam_instance_profile"></a> [panorama\_create\_iam\_instance\_profile](#input\_panorama\_create\_iam\_instance\_profile) | Enable creation of IAM Instance Profile and attach it to Panorama. | `bool` | `false` | no |
| <a name="input_panorama_create_iam_role"></a> [panorama\_create\_iam\_role](#input\_panorama\_create\_iam\_role) | Enable creation of IAM Role for IAM Instance Profile. | `bool` | `false` | no |
| <a name="input_panorama_create_public_ip"></a> [panorama\_create\_public\_ip](#input\_panorama\_create\_public\_ip) | Public access to Panorama. | `bool` | `false` | no |
| <a name="input_panorama_deployment_name"></a> [panorama\_deployment\_name](#input\_panorama\_deployment\_name) | Name of Panorama deployment, further use for tagging and name of Panorama instance. | `string` | `"panorama"` | no |
| <a name="input_panorama_ebs_encrypted"></a> [panorama\_ebs\_encrypted](#input\_panorama\_ebs\_encrypted) | Whether to enable EBS encryption on volumes.. | `bool` | `true` | no |
| <a name="input_panorama_ebs_kms_key_alias"></a> [panorama\_ebs\_kms\_key\_alias](#input\_panorama\_ebs\_kms\_key\_alias) | KMS key alias used for encrypting Panorama EBS. | `string` | `""` | no |
| <a name="input_panorama_ebs_volumes"></a> [panorama\_ebs\_volumes](#input\_panorama\_ebs\_volumes) | List of Panorama volumes | `list(any)` | `[]` | no |
| <a name="input_panorama_existing_iam_role_name"></a> [panorama\_existing\_iam\_role\_name](#input\_panorama\_existing\_iam\_role\_name) | If you want to use existing IAM Role as IAM Instance Profile use this variable to provide IAM Role name." | `string` | `""` | no |
| <a name="input_panorama_iam_policy_name"></a> [panorama\_iam\_policy\_name](#input\_panorama\_iam\_policy\_name) | If you want to use existing IAM Policy in Terraform created IAM Role, provide IAM Role name with this variable." | `string` | `""` | no |
| <a name="input_panorama_ssh_key_name"></a> [panorama\_ssh\_key\_name](#input\_panorama\_ssh\_key\_name) | SSH key used to login into Panorama EC2 server. | `string` | n/a | yes |
| <a name="input_panorama_version"></a> [panorama\_version](#input\_panorama\_version) | Panorama OS Version. | `string` | `"10.2.0"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region. | `string` | `"us-east-1"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | AWS VPC Cidr block. | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC Name. | `string` | `"security-vpc"` | no |
| <a name="input_vpc_routes_outbound_destin_cidrs"></a> [vpc\_routes\_outbound\_destin\_cidrs](#input\_vpc\_routes\_outbound\_destin\_cidrs) | VPC Routes outbound cidr | `list(string)` | n/a | yes |
| <a name="input_vpc_security_groups"></a> [vpc\_security\_groups](#input\_vpc\_security\_groups) | Security VPC security groups settings.<br>Structure looks like this:<pre>{<br>  security_group_name = {<br>    {<br>      name = "security_group_name"<br>      rules = {<br>        all_outbound = {<br>          description = "Permit All traffic outbound"<br>          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>        https = {<br>          description = "Permit HTTPS"<br>          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>        ssh = {<br>          description = "Permit SSH"<br>          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>      }<br>    }<br>  }<br>}</pre> | `map(any)` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Security VPC subnets CIDR | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_panorama_private_ip"></a> [panorama\_private\_ip](#output\_panorama\_private\_ip) | Panorama instance private IP. |
| <a name="output_panorama_url"></a> [panorama\_url](#output\_panorama\_url) | Panorama instance URL. |
<!-- END_TF_DOCS -->