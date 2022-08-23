# Palo Alto Networks VM-Series NGFW Module Example for AWS Cloud

A Terraform module example for deploying a VM-Series NGFW in AWS Cloud using the [User Data](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/bootstrap-the-vm-series-firewall/choose-a-bootstrap-method.html#idf6412176-e973-488e-9d7a-c568fe1e33a9_id3433e9c0-a589-40d5-b0bd-4bc42234aa0f) bootstrap method.

This example can be used to familarize oneself with both the VM-Series NGFW  and Terraform - it creates a single instance of virtualized firewall in a Security VPC with a management-only interface and lacks any traffic inspection.

For a more complex scenario of using the `vmseries` module - including traffic inspection, check the rest of our [Examples](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/examples).

**NOTE:**
The Security Group attached to the Management interface uses an inbound rule allowing traffic to port `22` and `443` from `0.0.0.0/0`, which means that SSH and HTTP access to the NFGW is possible from all over the Internet. You should update the Security Group rules and limit access to the Management interface, for example - to only the public IP address from which you will connect to VM-Series.

## Usage

Create a `terraform.tfvars` file and copy the content of `example.tfvars` into it, adjust if needed.

Then execute:

```sh
terraform init
terraform apply
terraform output -json mgmt_eip
```

Connect through SSH to the VM-Series Management interface IP address using the SSH key you provided as the  `ssh_key_name` parameter in your `terraform.tfvars` file:

```sh
ssh <username>@<mgmt_eip> -i <path_to_your_private_ssh_key>
```

## Cleanup

To delete all the resources created by the previous `apply` attempts, execute:

```sh
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.25 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_security_subnet_sets"></a> [security\_subnet\_sets](#module\_security\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_security_vpc"></a> [security\_vpc](#module\_security\_vpc) | ../../modules/vpc | n/a |
| <a name="module_security_vpc_routes"></a> [security\_vpc\_routes](#module\_security\_vpc\_routes) | ../../modules/vpc_route | n/a |
| <a name="module_vmseries"></a> [vmseries](#module\_vmseries) | ../../modules/vmseries | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bootstrap_options"></a> [bootstrap\_options](#input\_bootstrap\_options) | n/a | `any` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | n/a | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_cidr"></a> [security\_vpc\_cidr](#input\_security\_vpc\_cidr) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_name"></a> [security\_vpc\_name](#input\_security\_vpc\_name) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_destin_cidrs"></a> [security\_vpc\_routes\_outbound\_destin\_cidrs](#input\_security\_vpc\_routes\_outbound\_destin\_cidrs) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_security_groups"></a> [security\_vpc\_security\_groups](#input\_security\_vpc\_security\_groups) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_subnets"></a> [security\_vpc\_subnets](#input\_security\_vpc\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | n/a | `any` | n/a | yes |
| <a name="input_vmseries"></a> [vmseries](#input\_vmseries) | n/a | `any` | n/a | yes |
| <a name="input_vmseries_version"></a> [vmseries\_version](#input\_vmseries\_version) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Map of public IPs created within the module. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
