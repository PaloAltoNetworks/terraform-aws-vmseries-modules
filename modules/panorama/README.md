# Palo Alto Networks Panorama Module for AWS

A Terraform module for deploying Panorama in AWS cloud.

Panorama deployed on AWS is Bring Your Own License (BYOL), supports all deployment modes (Panorama, Log Collector, and Management Only), and shares the same processes and functionality as the M-Series hardware appliances. For more information on Panorama modes, see [Panorama Models](https://docs.paloaltonetworks.com/panorama/8-1/panorama-admin/panorama-overview/panorama-models.html#id6a2d6388-f727-45aa-ae7e-ef7599379871).

## Usage

```hcl
locals {
  subnets_map = {
    "mgmt" = "subnet-0b67c0660aae33e2a"
  }

  security_groups_map = {
    "sg1" = "sg-0f4bf202f60c9a159"
  }
}

module "panorama" {
  source              = "../../modules/panorama/"
  panorama_version    = var.panorama_version
  global_tags         = var.global_tags
  panoramas           = var.panoramas
  subnets_map         = local.subnets_map
  security_groups_map = local.security_groups_map
}
```

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
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to add to all resources. | `map(any)` | `{}` | no |
| <a name="input_pano_license_type"></a> [pano\_license\_type](#input\_pano\_license\_type) | Select License type (byol only for Panorama) | `string` | `"byol"` | no |
| <a name="input_pano_license_type_map"></a> [pano\_license\_type\_map](#input\_pano\_license\_type\_map) | Map of Panorama licence types and corresponding Panorama Amazon Machine Image (AMI) ID.<br>The key is the licence type, and the value is the Panorama AMI ID." | `map(string)` | <pre>{<br>  "byol": "eclz7j04vu9lf8ont8ta3n17o"<br>}</pre> | no |
| <a name="input_panorama_version"></a> [panorama\_version](#input\_panorama\_version) | Panorama version to deploy. For example: "8.1.2". | `string` | `"10.0.2"` | no |
| <a name="input_panoramas"></a> [panoramas](#input\_panoramas) | Map of Panoramas to be built. | `any` | `{}` | no |
| <a name="input_security_groups_map"></a> [security\_groups\_map](#input\_security\_groups\_map) | Map of security group name to ID, can be passed from remote state output or data source.<br><br>Example:<pre>security_groups_map = {<br>  "panorama-mgmt-inbound-sg" = "sg-0e1234567890"<br>  "panorama-mgmt-outbound-sg" = "sg-0e1234567890"<br>}</pre> | `map(any)` | `{}` | no |
| <a name="input_subnets_map"></a> [subnets\_map](#input\_subnets\_map) | Map of subnet name to ID, can be passed from remote state output or data source.<br><br>Example:<pre>subnets_map = {<br>  "panorama-mgmt-1a" = "subnet-0e1234567890"<br>  "panorama-mgmt-1b" = "subnet-0e1234567890"<br>}</pre> | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_panoramas"></a> [panoramas](#output\_panoramas) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
