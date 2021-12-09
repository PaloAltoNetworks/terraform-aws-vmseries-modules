# Palo Alto Networks Panorama Module for AWS

A Terraform module for deploying Panorama in AWS cloud.

Panorama deployed on AWS is Bring Your Own License (BYOL), supports all deployment modes (Panorama, Log Collector, and Management Only), and shares the same processes and functionality as the M-Series hardware appliances. For more information on Panorama modes, see [Panorama Models](https://docs.paloaltonetworks.com/panorama/8-1/panorama-admin/panorama-overview/panorama-models.html#id6a2d6388-f727-45aa-ae7e-ef7599379871).

## Usage

For usage, check the "examples" folder in the root of the repository.

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
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability zone in which Panorama will be deployed. | `string` | n/a | yes |
| <a name="input_create_public_ip"></a> [create\_public\_ip](#input\_create\_public\_ip) | If true, create an Elastic IP address for Panorama. | `bool` | `false` | no |
| <a name="input_ebs_device_name"></a> [ebs\_device\_name](#input\_ebs\_device\_name) | The EBS device name to expose to the instance (for example, /dev/sdh or xvdh).<br>See [Device Naming on Linux Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html#available-ec2-device-names) for more information. | `string` | `"/dev/sdb"` | no |
| <a name="input_ebs_encrypted"></a> [ebs\_encrypted](#input\_ebs\_encrypted) | If true, the Panorama EBS volume will be encrypted. | `bool` | `false` | no |
| <a name="input_ebs_size"></a> [ebs\_size](#input\_ebs\_size) | The size of the EBS volume in GiBs. | `string` | `"2000"` | no |
| <a name="input_force_detach"></a> [force\_detach](#input\_force\_detach) | Set to true if you want to force the volume to detach. Useful if previous attempts failed, but use this option only as a last resort, as this can result in data loss. | `bool` | `false` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to assign to the resources.<br>If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level." | `map(any)` | `{}` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for Panorama. Default set to Palo Alto Networks recommended instance type. | `string` | `"c5.4xlarge"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The ARN for the KMS encryption key. When specifying `kms_key_id`, the `ebs_encrypted` variable needs to be set to true.<br>If the `kms_key_id` is not provided but the `ebs_encrypted` is set to `true`, the default EBS encryption KMS key in the current region will be used.<br><br>\_\_Note\_\_: Terraform must be running with credentials which have the `GenerateDataKeyWithoutPlaintext` permission on the specified KMS key <br>as required by the [EBS KMS CMK volume provisioning process](https://docs.aws.amazon.com/kms/latest/developerguide/services-ebs.html#ebs-cmk) to prevent a volume from being created and almost immediately deleted.<br>If null, the default EBS encryption KMS key in the current region is used. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Panorama instance. | `string` | `"pan-panorama"` | no |
| <a name="input_panorama_version"></a> [panorama\_version](#input\_panorama\_version) | Panorama PAN-OS Software version. List published images with:<pre>aws ec2 describe-images \\<br>--filters "Name=product-code,Values=eclz7j04vu9lf8ont8ta3n17o" "Name=name,Values=Panorama-AWS*" \\<br>--output json --query "Images[].Description" \| grep -o 'Panorama-AWS-.*' \| tr -d '",'</pre> | `string` | `"10.0.6"` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | If provided, associates a private IP address to the Panorama instance. | `string` | `null` | no |
| <a name="input_product_code"></a> [product\_code](#input\_product\_code) | Product code for Panorama BYOL license. | `string` | `"eclz7j04vu9lf8ont8ta3n17o"` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | Set this to true if you do not wish to detach the volume from the instance to which it is attached at destroy time, and instead just remove the attachment from Terraform state. <br>  This is useful when destroying an instance attached to third-party volumes. | `bool` | `false` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | AWS EC2 key pair name. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | VPC Subnet ID to launch Panorama in. | `string` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | A list of security group IDs to associate Panorama with. | `list(any)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mgmt_ip_address"></a> [mgmt\_ip\_address](#output\_mgmt\_ip\_address) | Panorama management IP address. If `create_public_ip` was `true`, it is a public IP address, otherwise a private IP address. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
