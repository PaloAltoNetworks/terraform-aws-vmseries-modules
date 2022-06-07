# Palo Alto Networks VM-Series NGFW Module Example for AWS Cloud

A Terraform module example allowing to deploy two instances of the Palo Alto Networks VM-Series NGFW combined with a [Gateway Load Balancer](https://aws.amazon.com/elasticloadbalancing/gateway-load-balancer/#:~:text=Gateway%20Load%20Balancer%20helps%20you,or%20down%2C%20based%20on%20demand.) and a [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) in AWS Cloud.

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gwlbe_outbound"></a> [gwlbe\_outbound](#module\_gwlbe\_outbound) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_security_gwlb"></a> [security\_gwlb](#module\_security\_gwlb) | ../../modules/gwlb | n/a |
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
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | n/a | `any` | n/a | yes |
| <a name="input_firewalls"></a> [firewalls](#input\_firewalls) | n/a | `any` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_endpoint_set_outbound_name"></a> [gwlb\_endpoint\_set\_outbound\_name](#input\_gwlb\_endpoint\_set\_outbound\_name) | n/a | `any` | n/a | yes |
| <a name="input_gwlb_name"></a> [gwlb\_name](#input\_gwlb\_name) | n/a | `any` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | ## General | `any` | n/a | yes |
| <a name="input_security_vpc_cidr"></a> [security\_vpc\_cidr](#input\_security\_vpc\_cidr) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_name"></a> [security\_vpc\_name](#input\_security\_vpc\_name) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_destin_cidrs"></a> [security\_vpc\_routes\_outbound\_destin\_cidrs](#input\_security\_vpc\_routes\_outbound\_destin\_cidrs) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_source_cidrs"></a> [security\_vpc\_routes\_outbound\_source\_cidrs](#input\_security\_vpc\_routes\_outbound\_source\_cidrs) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_security_groups"></a> [security\_vpc\_security\_groups](#input\_security\_vpc\_security\_groups) | n/a | `any` | n/a | yes |
| <a name="input_security_vpc_subnets"></a> [security\_vpc\_subnets](#input\_security\_vpc\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | n/a | `any` | n/a | yes |
| <a name="input_vmseries_version"></a> [vmseries\_version](#input\_vmseries\_version) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Map of public IPs created within the module. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->