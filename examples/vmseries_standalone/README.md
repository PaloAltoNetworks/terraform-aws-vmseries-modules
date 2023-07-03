---
show_in_hub: false
---
# Palo Alto Networks VM-Series NGFW Module Example for AWS Cloud

A Terraform module example for deploying a VM-Series NGFW in AWS Cloud using the [User Data](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/bootstrap-the-vm-series-firewall/choose-a-bootstrap-method.html#idf6412176-e973-488e-9d7a-c568fe1e33a9_id3433e9c0-a589-40d5-b0bd-4bc42234aa0f) bootstrap method.

This example can be used to familarize oneself with both the VM-Series NGFW  and Terraform - it creates a single instance of virtualized firewall in a Security VPC with a management-only interface and lacks any traffic inspection.

For a more complex scenario of using the `vmseries` module - including traffic inspection, check the rest of our [Examples](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/examples).

**NOTE:**
The Security Group attached to the Management interface uses an inbound rule allowing traffic to port `22` and `443` from `0.0.0.0/0`, which means that SSH and HTTP access to the NFGW is possible from all over the Internet. You should update the Security Group rules and limit access to the Management interface, for example - to only the public IP address from which you will connect to VM-Series.

## Topology

The topology consists of :
 - VPC with 1 subnet in 1 availability zones
 - 1 VM-Series instances with a public IP address and static private IP address

 ![](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/assets/9674179/9e41457a-0465-4e73-8a4a-8ab20e4cf3ad)

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

## Reference
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.25 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.25 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_vmseries"></a> [vmseries](#module\_vmseries) | ../../modules/vmseries | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | ../../modules/vpc_route | n/a |

### Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.vm_series_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.vm_series_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vm_series_ec2_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_vmseries"></a> [vmseries](#input\_vmseries) | A map defining VM-Series instances<br>Following properties are available:<br>- `instances`: map of VM-Series instances<br>- `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama<br>- `panos_version`: PAN-OS version used for VM-Series<br>- `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series<br>- `vpc`: key of VPC<br>Example:<pre>vmseries = {<br>  vmseries = {<br>    instances = {<br>      "01" = { az = "eu-central-1a" }<br>    }<br>    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`<br>    bootstrap_options = {<br>      mgmt-interface-swap         = "enable"<br>      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"<br>      dhcp-send-hostname          = "yes"<br>      dhcp-send-client-id         = "yes"<br>      dhcp-accept-server-hostname = "yes"<br>      dhcp-accept-server-domain   = "yes"<br>    }<br>    panos_version = "10.2.3"        # TODO: update here<br>    ebs_kms_id    = "alias/aws/ebs" # TODO: update here<br><br>    # Value of `vpc` must match key of objects stored in `vpcs`<br>    vpc = "security_vpc"<br><br>    interfaces = {<br>      mgmt = {<br>        device_index      = 1<br>        private_ip        = "10.100.0.4"<br>        security_group    = "vmseries_mgmt"<br>        vpc_subnet        = "security_vpc-mgmt"<br>        create_public_ip  = true<br>        source_dest_check = true<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    instances = map(object({<br>      az = string<br>    }))<br><br>    bootstrap_options = object({<br>      mgmt-interface-swap         = string<br>      plugin-op-commands          = string<br>      dhcp-send-hostname          = string<br>      dhcp-send-client-id         = string<br>      dhcp-accept-server-hostname = string<br>      dhcp-accept-server-domain   = string<br>    })<br><br>    panos_version = string<br>    ebs_kms_id    = string<br><br>    vpc = string<br><br>    interfaces = map(object({<br>      device_index      = number<br>      private_ip        = string<br>      security_group    = string<br>      vpc_subnet        = string<br>      create_public_ip  = bool<br>      source_dest_check = bool<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br><br>Following properties are available:<br>- `name`: VPC name<br>- `cidr`: CIDR for VPC<br>- `nacls`: map of network ACLs<br>- `security_groups`: map of security groups<br>- `subnets`: map of subnets with properties:<br>   - `az`: availability zone<br>   - `set`: internal identifier referenced by main.tf<br>   - `nacl`: key of NACL (can be null)<br>- `routes`: map of routes with properties:<br>   - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`<br>   - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources<br>   - `next_hop_type` - internet\_gateway, nat\_gateway, transit\_gateway\_attachment or gwlbe\_endpoint<br><br>Example:<pre>vpcs = {<br>  example_vpc = {<br>    name = "example-spoke-vpc"<br>    cidr = "10.104.0.0/16"<br>    nacls = {<br>      trusted_path_monitoring = {<br>        name               = "trusted-path-monitoring"<br>        rules = {<br>          allow_inbound = {<br>            rule_number = 300<br>            egress      = false<br>            protocol    = "-1"<br>            rule_action = "allow"<br>            cidr_block  = "0.0.0.0/0"<br>            from_port   = null<br>            to_port     = null<br>          }<br>        }<br>      }<br>    }<br>    security_groups = {<br>      example_vm = {<br>        name = "example_vm"<br>        rules = {<br>          all_outbound = {<br>            description = "Permit All traffic outbound"<br>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>            cidr_blocks = ["0.0.0.0/0"]<br>          }<br>        }<br>      }<br>    }<br>    subnets = {<br>      "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }<br>    }<br>    routes = {<br>      vm_default = {<br>        vpc_subnet    = "app1_vpc-app1_vm"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1"<br>        next_hop_type = "transit_gateway_attachment"<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name = string<br>    cidr = string<br>    nacls = map(object({<br>      name = string<br>      rules = map(object({<br>        rule_number = number<br>        egress      = bool<br>        protocol    = string<br>        rule_action = string<br>        cidr_block  = string<br>        from_port   = string<br>        to_port     = string<br>      }))<br>    }))<br>    security_groups = map(object({<br>      name = string<br>      rules = map(object({<br>        description = string<br>        type        = string,<br>        from_port   = string<br>        to_port     = string,<br>        protocol    = string<br>        cidr_blocks = list(string)<br>      }))<br>    }))<br>    subnets = map(object({<br>      az   = string<br>      set  = string<br>      nacl = string<br>    }))<br>    routes = map(object({<br>      vpc_subnet    = string<br>      to_cidr       = string<br>      next_hop_key  = string<br>      next_hop_type = string<br>    }))<br>  }))</pre> | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_vmseries_public_ips"></a> [vmseries\_public\_ips](#output\_vmseries\_public\_ips) | Map of public IPs created within `vmseries` module instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
