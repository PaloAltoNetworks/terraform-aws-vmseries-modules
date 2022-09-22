# Palo Alto Networks Autoscaling Group Module for AWS

A Terraform module for deploying VM-Series in Autoscaling group in AWS cloud. 

## Usage

For example usage, please refer to the [Examples](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/examples) directory.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0, < 2.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.25 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.25 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_lifecycle_hook.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [archive_file.this](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_name"></a> [asg\_name](#input\_asg\_name) | Name of the autoscaling group to create | `string` | `"asg"` | no |
| <a name="input_bootstrap_options"></a> [bootstrap\_options](#input\_bootstrap\_options) | Bootstrap options to put into userdata | `map(any)` | `{}` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | n/a | `number` | `2` | no |
| <a name="input_fw_license_type"></a> [fw\_license\_type](#input\_fw\_license\_type) | Select License type (byol/payg1/payg2) | `string` | `"byol"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. | `string` | `"m5.xlarge"` | no |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | Map of the network interface specifications.<br>If "mgmt-interface-swap" bootstrap option is enabled, ensure dataplane interface `device_index` is set to 0 and the firewall management interface `device_index` is set to 1.<br>Available options:<br>- `device_index`       = (Required\|int) Determines order in which interfaces are attached to the instance. Interface with `0` is attached at boot time.<br>- `subnet_id`          = (Required\|string) Subnet ID to create the ENI in.<br>- `name`               = (Optional\|string) Name tag for the ENI. Defaults to instance name suffixed by map's key.<br>- `description`        = (Optional\|string) A descriptive name for the ENI.<br>- `create_public_ip`   = (Optional\|bool) Whether to create a public IP for the ENI. Defaults to false.<br>- `eip_allocation_id`  = (Optional\|string) Associate an existing EIP to the ENI.<br>- `private_ips`        = (Optional\|list) List of private IPs to assign to the ENI. If not set, dynamic allocation is used.<br>- `public_ipv4_pool`   = (Optional\|string) EC2 IPv4 address pool identifier.<br>- `source_dest_check`  = (Optional\|bool) Whether to enable source destination checking for the ENI. Defaults to false.<br>- `security_group_ids` = (Optional\|list) A list of Security Group IDs to assign to this interface. Defaults to null.<br><br>Example:<pre>interfaces = {<br>  mgmt = {<br>    device_index       = 0<br>    subnet_id          = aws_subnet.mgmt.id<br>    name               = "mgmt"<br>    create_public_ip   = true<br>    source_dest_check  = true<br>    security_group_ids = ["sg-123456"]<br>  },<br>  public = {<br>    device_index     = 1<br>    subnet_id        = aws_subnet.public.id<br>    name             = "public"<br>    create_public_ip = true<br>  },<br>  private = {<br>    device_index = 2<br>    subnet_id    = aws_subnet.private.id<br>    name         = "private"<br>  },<br>]</pre> | `map(any)` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | n/a | `number` | `10` | no |
| <a name="input_lifecycle_hook_timeout"></a> [lifecycle\_hook\_timeout](#input\_lifecycle\_hook\_timeout) | How long should we wait for lambda to finish | `number` | `300` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | n/a | `number` | `2` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | n/a | `number` | `1` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | All resource names will be prepended with this string | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of AWS keypair to associate with instances | `string` | n/a | yes |
| <a name="input_vmseries_ami_id"></a> [vmseries\_ami\_id](#input\_vmseries\_ami\_id) | The AMI from which to launch the instance. Takes precedence over fw\_version and fw\_license\_type | `string` | `null` | no |
| <a name="input_vmseries_product_code"></a> [vmseries\_product\_code](#input\_vmseries\_product\_code) | Product code corresponding to a chosen VM-Series license type model - by default - BYOL.<br>To check the available license type models and their codes, please refer to the<br>[VM-Series documentation](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/obtain-the-ami/get-amazon-machine-image-ids.html) | `string` | `"6njl1pau431dv1qxipg63mvah"` | no |
| <a name="input_vmseries_version"></a> [vmseries\_version](#input\_vmseries\_version) | Select which FW version to deploy | `string` | `"10.2.2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg"></a> [asg](#output\_asg) | n/a |
<!-- END_TF_DOCS -->