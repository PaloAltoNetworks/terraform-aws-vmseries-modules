# Palo Alto Networks VM-Series Module for AWS

A Terraform module for deploying a VM-Series firewall in AWS cloud.

## Usage

```hcl
module "vmseries" {
  source              = "../../modules/vmseries/"

  name
  vmseries_version  = "10.1.3"
  interfaces        = var.interfaces
  bootstrap_options = var.bootstrap_options
  ssh_key_name      = var.ssh_key_name
  tags              = var.global_tags
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bootstrap_options"></a> [bootstrap\_options](#input\_bootstrap\_options) | VM-Series bootstrap options to provide using instance user data. Contents determine type of bootstap method to use.<br>If empty (the default), bootstrap process is not triggered at all.<br>For more information on available methods, please refer to VM-Series documentation for specific version.<br>For 10.0 docs are available [here](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/bootstrap-the-vm-series-firewall.html). | `string` | `""` | no |
| <a name="input_ebs_encrypted"></a> [ebs\_encrypted](#input\_ebs\_encrypted) | Whether to enable EBS encryption on volumes. | `bool` | `false` | no |
| <a name="input_ebs_kms_key_id"></a> [ebs\_kms\_key\_id](#input\_ebs\_kms\_key\_id) | The ARN for the KMS key to use for volume encryption. | `string` | `null` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM instance profile. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. | `string` | `"m5.xlarge"` | no |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | Map of the network interface specifications.<br>If "mgmt-interface-swap" bootstrap option is enabled, ensure dataplane interface `device_index` is set to 0 and the firewall management interface `device_index` is set to 1.<br>Available options:<br>- `device_index`       = (Required\|int) Determines order in which interfaces are attached to the instance. Interface with `0` is attached at boot time.<br>- `subnet_id`          = (Required\|string) Subnet ID to create the ENI in.<br>- `name`               = (Optional\|string) Name tag for the ENI. Defaults to instance name suffixed by map's key.<br>- `description`        = (Optional\|string) A descriptive name for the ENI.<br>- `create_public_ip`   = (Optional\|bool) Whether to create a public IP for the ENI. Defaults to false.<br>- `eip_allocation_id`  = (Optional\|string) Associate an existing EIP to the ENI.<br>- `private_ips`        = (Optional\|list) List of private IPs to assign to the ENI. If not set, dynamic allocation is used.<br>- `public_ipv4_pool`   = (Optional\|string) EC2 IPv4 address pool identifier. <br>- `source_dest_check`  = (Optional\|bool) Whether to enable source destination checking for the ENI. Defaults to false.<br>- `security_group_ids` = (Optional\|list) A list of Security Group IDs to assign to this interface. Defaults to null.<br><br>Example:<pre>interfaces = {<br>  mgmt = {<br>    device_index       = 0<br>    subnet_id          = aws_subnet.mgmt.id<br>    name               = "mgmt"<br>    create_public_ip   = true<br>    source_dest_check  = true<br>    security_group_ids = ["sg-123456"]<br>  },<br>  public = {<br>    device_index     = 1<br>    subnet_id        = aws_subnet.public.id<br>    name             = "public"<br>    create_public_ip = true<br>  },<br>  private = {<br>    device_index = 2<br>    subnet_id    = aws_subnet.private.id<br>    name         = "private"<br>  },<br>]</pre> | `map(any)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the VM-Series instance. | `string` | `null` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of AWS keypair to associate with instances. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of additional tags to apply to all resources. | `map(any)` | `{}` | no |
| <a name="input_vmseries_ami_id"></a> [vmseries\_ami\_id](#input\_vmseries\_ami\_id) | Specific AMI ID to use for VM-Series instance.<br>If `null` (the default), `vmseries_version` and `vmseries_product_code` vars are used to determine a public image to use. | `string` | `null` | no |
| <a name="input_vmseries_product_code"></a> [vmseries\_product\_code](#input\_vmseries\_product\_code) | Product code corresponding to a chosen VM-Series license type model - by default - BYOL. <br>To check the available license type models and their codes, please refer to the<br>[VM-Series documentation](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/obtain-the-ami/get-amazon-machine-image-ids.html) | `string` | `"6njl1pau431dv1qxipg63mvah"` | no |
| <a name="input_vmseries_version"></a> [vmseries\_version](#input\_vmseries\_version) | VM-Series Firewall version to deploy.<br>To list all available VM-Series versions, run the command provided below. <br>Please have in mind that the `product-code` may need to be updated - check the `vmseries_product_code` variable for more information.<pre>aws ec2 describe-images --region us-west-1 --filters "Name=product-code,Values=6njl1pau431dv1qxipg63mvah" "Name=name,Values=PA-VM-AWS*" --output json --query "Images[].Description" \| grep -o 'PA-VM-AWS-.*' \| sort</pre> | `string` | `"10.0.8-h8"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance"></a> [instance](#output\_instance) | n/a |
| <a name="output_interfaces"></a> [interfaces](#output\_interfaces) | Map of VM-Series network interfaces. The entries are `aws_network_interface` objects. |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Map of public IPs created within the module. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
