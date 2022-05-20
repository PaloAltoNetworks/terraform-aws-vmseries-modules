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
| [aws_iam_instance_profile.panorama_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy_attachment.panorama_iam_ro_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.panorama_read_only_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_kms_alias.panorama_instance_ebs_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.panorama_instance_ebs_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability zone in which Panorama will be deployed. | `string` | n/a | yes |
| <a name="input_create_custom_kms_key_for_ebs"></a> [create\_custom\_kms\_key\_for\_ebs](#input\_create\_custom\_kms\_key\_for\_ebs) | Create custom KMS key to be later used in encrypt EBS. | `bool` | `false` | no |
| <a name="input_create_public_ip"></a> [create\_public\_ip](#input\_create\_public\_ip) | If true, create an Elastic IP address for Panorama. | `bool` | `false` | no |
| <a name="input_create_read_only_iam_role"></a> [create\_read\_only\_iam\_role](#input\_create\_read\_only\_iam\_role) | Create read only IAM Role and attach it to Panorama instance. | `bool` | `false` | no |
| <a name="input_ebs_volumes"></a> [ebs\_volumes](#input\_ebs\_volumes) | List of EBS volumes to create and attach to Panorama.<br>Available options:<br>- `name`              (Optional) Name tag for the EBS volume. If not provided defaults to the value of `var.name`.<br>- `ebs_device_name`   (Required) The EBS device name to expose to the instance (for example, /dev/sdh or xvdh). <br>See [Device Naming on Linux Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html#available-ec2-device-names) for more information.<br>- `ebs_size`          (Optional) The size of the EBS volume in GiBs. Defaults to 2000 GiB.<br>- `ebs_encrypted`     (Optional) If true, the Panorama EBS volume will be encrypted.<br>- `force_detach`      (Optional) Set to true if you want to force the volume to detach. Useful if previous attempts failed, but use this option only as a last resort, as this can result in data loss.<br>- `skip_destroy`      (Optional) Set this to true if you do not wish to detach the volume from the instance to which it is attached at destroy time, and instead just remove the attachment from Terraform state. <br>This is useful when destroying an instance attached to third-party volumes.<br>- `kms_key_id`        (Optional) The ARN for the KMS encryption key. When specifying `kms_key_id`, the `ebs_encrypted` variable needs to be set to true.<br>If the `kms_key_id` is not provided but the `ebs_encrypted` is set to `true`, the default EBS encryption KMS key in the current region will be used.<br><br>Note: Terraform must be running with credentials which have the `GenerateDataKeyWithoutPlaintext` permission on the specified KMS key <br>as required by the [EBS KMS CMK volume provisioning process](https://docs.aws.amazon.com/kms/latest/developerguide/services-ebs.html#ebs-cmk) to prevent a volume from being created and almost immediately deleted.<br>If null, the default EBS encryption KMS key in the current region is used.<br><br>Example:<pre>ebs_volumes = [<br>  {<br>    name              = "ebs-1"<br>    ebs_device_name   = "/dev/sdb"<br>    ebs_size          = "2000"<br>    ebs_encrypted     = true<br>    kms_key_id        = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"<br>  },<br>  {<br>    name              = "ebs-2"<br>    ebs_device_name   = "/dev/sdb"<br>    ebs_size          = "2000"<br>    ebs_encrypted     = true<br>  },<br>  {<br>    name              = "ebs-3"<br>    ebs_device_name   = "/dev/sdb"<br>    ebs_size          = "2000"<br>  },<br>]</pre> | `list(any)` | `[]` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to assign to the resources.<br>If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level." | `map(any)` | `{}` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for Panorama. Default set to Palo Alto Networks recommended instance type. | `string` | `"c5.4xlarge"` | no |
| <a name="input_kms_cmk_spec"></a> [kms\_cmk\_spec](#input\_kms\_cmk\_spec) | Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing<br>algorithms that the key supports.<br>Valid values: SYMMETRIC\_DEFAULT, RSA\_2048, RSA\_3072, RSA\_4096, HMAC\_256,<br>ECC\_NIST\_P256, ECC\_NIST\_P384, ECC\_NIST\_P521, or ECC\_SECG\_P256K1." | `string` | `"SYMMETRIC_DEFAULT"` | no |
| <a name="input_kms_delete_window_in_days"></a> [kms\_delete\_window\_in\_days](#input\_kms\_delete\_window\_in\_days) | Number of days KMS key is stay until deleted. | `number` | `7` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Panorama instance. | `string` | `"pan-panorama"` | no |
| <a name="input_panorama_version"></a> [panorama\_version](#input\_panorama\_version) | Panorama PAN-OS Software version. List published images with:<pre>aws ec2 describe-images \\<br>--filters "Name=product-code,Values=eclz7j04vu9lf8ont8ta3n17o" "Name=name,Values=Panorama-AWS*" \\<br>--output json --query "Images[].Description" \| grep -o 'Panorama-AWS-.*' \| tr -d '",'</pre> | `string` | `"10.1.5"` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | If provided, associates a private IP address to the Panorama instance. | `string` | `null` | no |
| <a name="input_product_code"></a> [product\_code](#input\_product\_code) | Product code for Panorama BYOL license. | `string` | `"eclz7j04vu9lf8ont8ta3n17o"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | AWS EC2 key pair name. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | VPC Subnet ID to launch Panorama in. | `string` | n/a | yes |
| <a name="input_universal_name_prefix"></a> [universal\_name\_prefix](#input\_universal\_name\_prefix) | Prefix used for create individual environment via same account.<br>It help to organize multiple same origin resources." | `string` | `""` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | A list of security group IDs to associate Panorama with. | `list(any)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mgmt_ip_address"></a> [mgmt\_ip\_address](#output\_mgmt\_ip\_address) | Panorama management IP address. If `create_public_ip` was `true`, it is a public IP address, otherwise a private IP address. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
