<!-- BEGIN_TF_DOCS -->

## Info
Initial Panorama setup takes a few minutes to complete.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.75.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 3.3.0 |

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
| [aws_key_pair.generated_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [tls_private_key.RSA_panorama_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | Create ssh key. | `bool` | `false` | no |
| <a name="input_panorama_az"></a> [panorama\_az](#input\_panorama\_az) | Availability zone where Panorama was be deployed. | `string` | n/a | yes |
| <a name="input_panorama_create_public_ip"></a> [panorama\_create\_public\_ip](#input\_panorama\_create\_public\_ip) | Public access to Panorama. | `bool` | `false` | no |
| <a name="input_panorama_ssh_key"></a> [panorama\_ssh\_key](#input\_panorama\_ssh\_key) | SSH key used to login into Panorama EC2 server. | `string` | n/a | yes |
| <a name="input_panorama_version"></a> [panorama\_version](#input\_panorama\_version) | Panorama OS Version. | `string` | `"10.2"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix use for creating unique names. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region. | `string` | `"us-east-1"` | no |
| <a name="input_security_vpc_cidr"></a> [security\_vpc\_cidr](#input\_security\_vpc\_cidr) | AWS VPC Cidr block. | `string` | n/a | yes |
| <a name="input_security_vpc_name"></a> [security\_vpc\_name](#input\_security\_vpc\_name) | VPC Name. | `string` | `"security-vpc"` | no |
| <a name="input_security_vpc_routes_outbound_destin_cidrs"></a> [security\_vpc\_routes\_outbound\_destin\_cidrs](#input\_security\_vpc\_routes\_outbound\_destin\_cidrs) | VPC Routes outbound cidr | `string` | n/a | yes |
| <a name="input_vpc_security_groups"></a> [security\_vpc\_security\_groups](#input\_security\_vpc\_security\_groups) | Security VPC security groups settings.<br>Structure looks like this:<pre>{<br>  security_group_name = {<br>    {<br>      name = "security_group_name"<br>      rules = {<br>        all_outbound = {<br>          description = "Permit All traffic outbound"<br>          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>        https = {<br>          description = "Permit HTTPS"<br>          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>        ssh = {<br>          description = "Permit SSH"<br>          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>      }<br>    }<br>  }<br>}</pre> | `map(any)` | n/a | yes |
| <a name="input_security_vpc_subnets"></a> [security\_vpc\_subnets](#input\_security\_vpc\_subnets) | Security VPC subnets CIDR | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_panorama_url"></a> [panorama\_url](#output\_panorama\_url) | Panorama instance URL. |
<!-- END_TF_DOCS -->