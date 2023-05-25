# VM-Series in the Centralized Design Combined Inbound Architecture

Deployment of Palo Alto Networks VM-Series into a variation on one of its [Reference Architectures](https://pandocs.tech/fw/110p-prime): the *Centralized* design using *Combined Inbound Security*.

In a nutshell it means:

- A single Security VPC can protect multiple Application VPCs. Therefore these form the hub and spokes model,
  where the Security VPC is the hub and the Application VPCs are the spokes.
- The outbound dataplane traffic traverses the transit gateway (TGW) and the gateway load balancer (GWLB). It's interzone category.
- The inbound dataplane traffic _does not_ traverse TGW and only traverses GWLB. It's intrazone category.

## Topology diagram

![GWLB_TGW_Combined](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/assets/9674179/37a7ffc1-134a-4037-b174-5a2abe44f475)

## Running the example

To run this Terraform example copy the `example.tfvars` to `terraform.tfvars` and adjust it to your needs.

All Firewall VMs will be set up with an SSH key, so fill out the `ssh_key_name` property with existing Key Pair name.

A thing worth noticing is the Gateway Load Balancer (GWLB) configuration. AWS recommends that GWLB is set up in every Availability Zone available in a particular region. This example is set up for `eu-central-1` which has (at the time of writing) zones from `a` to `c`. When changing the region to one that has a different number of Availability Zones, make sure you adjust the GWLB set up accordingly. You can do it in the `vpcs` property - add od remove `subnets` for the `gwlb` set.

When `terraform.tfvars` is ready, run the following commands:

```
terraform init
terraform apply
```

To cleanup the infrastructure run:

```
terraform destroy
```

## Traffic Validation

If no errors occurred during deployment, configure the VM-Series machines as expected.
- Configure the data interface so that GWLB Health Checks work properly.
- All data interfaces should use DHCP
- Create subinterfaces for Inbound, Outbound and EastWest traffic
- Create appropriate zones that will be assigned to the correct subinterfaces
- Create a Deny All rule at the very end of the rule list to eliminate unwanted traffic to the environment (In the default configuration, due to the fact that we use subinterfaces, each traffic is seen as an intrazone)
- Create policies as needed
- Make sure GWLB sees all VM-Series in the target group as healthy
- Take the ALB address and see if we are able to get the welcome page from the test app
- Make sure all traffic is visible in the monitor tab in VM-Series (check if the traffic works as expected, if it goes to the right policies)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.25 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.25 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gwlb"></a> [gwlb](#module\_gwlb) | ../../modules/gwlb | n/a |
| <a name="module_gwlbe_endpoint"></a> [gwlbe\_endpoint](#module\_gwlbe\_endpoint) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_public_alb"></a> [public\_alb](#module\_public\_alb) | ../../modules/alb | n/a |
| <a name="module_public_nlb"></a> [public\_nlb](#module\_public\_nlb) | ../../modules/nlb | n/a |
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_transit_gateway"></a> [transit\_gateway](#module\_transit\_gateway) | ../../modules/transit_gateway | n/a |
| <a name="module_transit_gateway_attachment"></a> [transit\_gateway\_attachment](#module\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_vmseries"></a> [vmseries](#module\_vmseries) | ../../modules/vmseries | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | ../../modules/vpc_route | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_route.from_security_to_panorama](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.from_spokes_to_security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_iam_instance_profile.vm_series_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.vm_series_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vm_series_ec2_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.spoke_vms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_gwlb_endpoints"></a> [gwlb\_endpoints](#input\_gwlb\_endpoints) | A map defining GWLB endpoints.<br><br>Following properties are available:<br>- `name`: name of the GWLB endpoint<br>- `gwlb`: key of GWLB<br>- `vpc`: key of VPC<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic<br>- `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint<br><br>Example:<pre>gwlb_endpoints = {<br>  security_gwlb_eastwest = {<br>    name            = "eastwest-gwlb-endpoint"<br>    gwlb            = "security_gwlb"<br>    vpc             = "security_vpc"<br>    vpc_subnet      = "security_vpc-gwlbe_eastwest"<br>    act_as_next_hop = false<br>    to_vpc_subnets  = null<br>  }<br>}</pre> | <pre>map(object({<br>    name            = string<br>    gwlb            = string<br>    vpc             = string<br>    vpc_subnet      = string<br>    act_as_next_hop = bool<br>    to_vpc_subnets  = string<br>  }))</pre> | `{}` | no |
| <a name="input_gwlbs"></a> [gwlbs](#input\_gwlbs) | A map defining Gateway Load Balancers.<br><br>Following properties are available:<br>- `name`: name of the GWLB<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br><br>Example:<pre>gwlbs = {<br>  security_gwlb = {<br>    name       = "security-gwlb"<br>    vpc_subnet = "security_vpc-gwlb"<br>  }<br>}</pre> | <pre>map(object({<br>    name       = string<br>    vpc_subnet = string<br>  }))</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_natgws"></a> [natgws](#input\_natgws) | A map defining NAT Gateways.<br><br>Following properties are available:<br>- `name`: name of NAT Gateway<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br><br>Example:<pre>natgws = {<br>  security_nat_gw = {<br>    name       = "natgw"<br>    vpc_subnet = "security_vpc-natgw"<br>  }<br>}</pre> | <pre>map(object({<br>    name       = string<br>    vpc_subnet = string<br>  }))</pre> | `{}` | no |
| <a name="input_panorama"></a> [panorama](#input\_panorama) | A object defining TGW attachment and CIDR for Panorama.<br><br>Following properties are available:<br>- `transit_gateway_attachment_id`: ID of attachment for Panorama<br>- `vpc_cidr`: CIDR of the VPC, where Panorama is deployed<br><br>Example:<pre>panorama = {<br>  transit_gateway_attachment_id = "tgw-attach-123456789"<br>  vpc_cidr                      = "10.255.0.0/24"<br>}</pre> | <pre>object({<br>    transit_gateway_attachment_id = string<br>    vpc_cidr                      = string<br>  })</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_spoke_albs"></a> [spoke\_albs](#input\_spoke\_albs) | A map defining Application Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `rules`: Rules defining the method of traffic balancing<br>- `vms`: Instances to be the target group for ALB<br>- `vpc`: The VPC in which the load balancer is to be run<br>- `vpc_subnet`: The subnets in which the Load Balancer is to be run<br>- `security_gropus`: Security Groups to be associated with the ALB<pre></pre> | <pre>map(object({<br>    rules           = any<br>    vms             = list(string)<br>    vpc             = string<br>    vpc_subnet      = string<br>    security_groups = string<br>  }))</pre> | n/a | yes |
| <a name="input_spoke_nlbs"></a> [spoke\_nlbs](#input\_spoke\_nlbs) | A map defining Network Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `vms`: keys of spoke VMs<br><br>Example:<pre>spoke_lbs = {<br>  "app1-nlb" = {<br>    vpc_subnet = "app1_vpc-app1_lb"<br>    vms        = ["app1_vm01", "app1_vm02"]<br>  }<br>}</pre> | <pre>map(object({<br>    vpc_subnet = string<br>    vms        = list(string)<br>  }))</pre> | `{}` | no |
| <a name="input_spoke_vms"></a> [spoke\_vms](#input\_spoke\_vms) | A map defining VMs in spoke VPCs.<br><br>Following properties are available:<br>- `az`: name of the Availability Zone<br>- `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `security_group`: security group assigned to ENI used by VM<br>- `type`: EC2 type VM<br><br>Example:<pre>spoke_vms = {<br>  "app1_vm01" = {<br>    az             = "eu-central-1a"<br>    vpc            = "app1_vpc"<br>    vpc_subnet     = "app1_vpc-app1_vm"<br>    security_group = "app1_vm"<br>    type           = "t2.micro"<br>  }<br>}</pre> | <pre>map(object({<br>    az             = string<br>    vpc            = string<br>    vpc_subnet     = string<br>    security_group = string<br>    type           = string<br>  }))</pre> | `{}` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_tgw"></a> [tgw](#input\_tgw) | A object defining Transit Gateway.<br><br>Following properties are available:<br>- `create`: set to false, if existing TGW needs to be reused<br>- `id`:  id of existing TGW or null<br>- `name`: name of TGW to create or use<br>- `asn`: ASN number<br>- `route_tables`: map of route tables<br>- `attachments`: map of TGW attachments<br><br>Example:<pre>tgw = {<br>  create = true<br>  id     = null<br>  name   = "tgw"<br>  asn    = "64512"<br>  route_tables = {<br>    "from_security_vpc" = {<br>      create = true<br>      name   = "from_security"<br>    }<br>  }<br>  attachments = {<br>    security = {<br>      name                = "vmseries"<br>      vpc_subnet          = "security_vpc-tgw_attach"<br>      route_table         = "from_security_vpc"<br>      propagate_routes_to = "from_spoke_vpc"<br>    }<br>  }<br>}</pre> | <pre>object({<br>    create = bool<br>    id     = string<br>    name   = string<br>    asn    = string<br>    route_tables = map(object({<br>      create = bool<br>      name   = string<br>    }))<br>    attachments = map(object({<br>      name                = string<br>      vpc_subnet          = string<br>      route_table         = string<br>      propagate_routes_to = string<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_vmseries"></a> [vmseries](#input\_vmseries) | A map defining VM-Series instances<br>Following properties are available:<br>- `instances`: map of VM-Series instances<br>- `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama<br>- `panos_version`: PAN-OS version used for VM-Series<br>- `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series<br>- `vpc`: key of VPC<br>- `gwlb`: key of GWLB<br>- `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints<br>- `system_services`: map of system services<br>- `application_lb`: ALB placed in front of the Firewalls' public interfaces<br>- `network_lb`: NLB placed in front of the Firewalls' public interfaces<br>Example:<pre>vmseries = {<br>  vmseries = {<br>    instances = {<br>      "01" = { az = "eu-central-1a" }<br>      "02" = { az = "eu-central-1b" }<br>    }<br>    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`<br>    bootstrap_options = {<br>      mgmt-interface-swap         = "enable"<br>      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"<br>      dhcp-send-hostname          = "yes"<br>      dhcp-send-client-id         = "yes"<br>      dhcp-accept-server-hostname = "yes"<br>      dhcp-accept-server-domain   = "yes"<br>    }<br>    panos_version = "10.2.3"        # TODO: update here<br>    ebs_kms_id    = "alias/aws/ebs" # TODO: update here<br>    # Value of `vpc` must match key of objects stored in `vpcs`<br>    vpc = "security_vpc"<br>    # Value of `gwlb` must match key of objects stored in `gwlbs`<br>    gwlb = "security_gwlb"<br>    interfaces = {<br>      private = {<br>        device_index      = 0<br>        security_group    = "vmseries_private"<br>        vpc_subnet        = "security_vpc-private"<br>        create_public_ip  = false<br>        source_dest_check = false<br>      }<br>      mgmt = {<br>        device_index      = 1<br>        security_group    = "vmseries_mgmt"<br>        vpc_subnet        = "security_vpc-mgmt"<br>        create_public_ip  = true<br>        source_dest_check = true<br>      }<br>      public = {<br>        device_index      = 2<br>        security_group    = "vmseries_public"<br>        vpc_subnet        = "security_vpc-public"<br>        create_public_ip  = true<br>        source_dest_check = false<br>      }<br>    }<br>    # Value of `gwlb_endpoint` must match key of objects stored in `gwlb_endpoints`<br>    subinterfaces = {<br>      inbound = {<br>        app1 = {<br>          gwlb_endpoint = "app1_inbound"<br>          subinterface  = "ethernet1/1.11"<br>        }<br>        app2 = {<br>          gwlb_endpoint = "app2_inbound"<br>          subinterface  = "ethernet1/1.12"<br>        }<br>      }<br>      outbound = {<br>        only_1_outbound = {<br>          gwlb_endpoint = "security_gwlb_outbound"<br>          subinterface  = "ethernet1/1.20"<br>        }<br>      }<br>      eastwest = {<br>        only_1_eastwest = {<br>          gwlb_endpoint = "security_gwlb_eastwest"<br>          subinterface  = "ethernet1/1.30"<br>        }<br>      }<br>    }<br>    system_services = {<br>      dns_primary = "4.2.2.2"      # TODO: update here<br>      dns_secondy = null           # TODO: update here<br>      ntp_primary = "pool.ntp.org" # TODO: update here<br>      ntp_secondy = null           # TODO: update here<br>    }<br>    application_lb = null<br>    network_lb     = null<br>  }<br>}</pre> | <pre>map(object({<br>    instances = map(object({<br>      az = string<br>    }))<br><br>    bootstrap_options = object({<br>      mgmt-interface-swap         = string<br>      plugin-op-commands          = string<br>      panorama-server             = string<br>      auth-key                    = string<br>      dgname                      = string<br>      tplname                     = string<br>      dhcp-send-hostname          = string<br>      dhcp-send-client-id         = string<br>      dhcp-accept-server-hostname = string<br>      dhcp-accept-server-domain   = string<br>    })<br><br>    panos_version = string<br>    ebs_kms_id    = string<br><br>    vpc  = string<br>    gwlb = string<br><br>    interfaces = map(object({<br>      device_index      = number<br>      security_group    = string<br>      vpc_subnet        = string<br>      create_public_ip  = bool<br>      source_dest_check = bool<br>    }))<br><br>    subinterfaces = map(map(object({<br>      gwlb_endpoint = string<br>      subinterface  = string<br>    })))<br><br>    system_services = object({<br>      dns_primary = string<br>      dns_secondy = string<br>      ntp_primary = string<br>      ntp_secondy = string<br>    })<br><br>    application_lb = object({<br>      name  = string<br>      rules = any<br>    })<br><br>    network_lb = object({<br>      name  = string<br>      rules = any<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br><br>Following properties are available:<br>- `name`: VPC name<br>- `cidr`: CIDR for VPC<br>- `nacls`: map of network ACLs<br>- `security_groups`: map of security groups<br>- `subnets`: map of subnets with properties:<br>   - `az`: availability zone<br>   - `set`: internal identifier referenced by main.tf<br>   - `nacl`: key of NACL (can be null)<br>- `routes`: map of routes with properties:<br>   - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`<br>   - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources<br>   - `next_hop_type` - internet\_gateway, nat\_gateway, transit\_gateway\_attachment or gwlbe\_endpoint<br><br>Example:<pre>vpcs = {<br>  example_vpc = {<br>    name = "example-spoke-vpc"<br>    cidr = "10.104.0.0/16"<br>    nacls = {<br>      trusted_path_monitoring = {<br>        name               = "trusted-path-monitoring"<br>        rules = {<br>          allow_inbound = {<br>            rule_number = 300<br>            egress      = false<br>            protocol    = "-1"<br>            rule_action = "allow"<br>            cidr_block  = "0.0.0.0/0"<br>            from_port   = null<br>            to_port     = null<br>          }<br>        }<br>      }<br>    }<br>    security_groups = {<br>      example_vm = {<br>        name = "example_vm"<br>        rules = {<br>          all_outbound = {<br>            description = "Permit All traffic outbound"<br>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>            cidr_blocks = ["0.0.0.0/0"]<br>          }<br>        }<br>      }<br>    }<br>    subnets = {<br>      "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }<br>      "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }<br>    }<br>    routes = {<br>      vm_default = {<br>        vpc_subnet    = "app1_vpc-app1_vm"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1"<br>        next_hop_type = "transit_gateway_attachment"<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name = string<br>    cidr = string<br>    nacls = map(object({<br>      name = string<br>      rules = map(object({<br>        rule_number = number<br>        egress      = bool<br>        protocol    = string<br>        rule_action = string<br>        cidr_block  = string<br>        from_port   = string<br>        to_port     = string<br>      }))<br>    }))<br>    security_groups = map(object({<br>      name = string<br>      rules = map(object({<br>        description = string<br>        type        = string,<br>        from_port   = string<br>        to_port     = string,<br>        protocol    = string<br>        cidr_blocks = list(string)<br>      }))<br>    }))<br>    subnets = map(object({<br>      az   = string<br>      set  = string<br>      nacl = string<br>    }))<br>    routes = map(object({<br>      vpc_subnet    = string<br>      to_cidr       = string<br>      next_hop_key  = string<br>      next_hop_type = string<br>    }))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_load_balancers"></a> [application\_load\_balancers](#output\_application\_load\_balancers) | FQDNs of Application Load Balancers |
| <a name="output_network_load_balancers"></a> [network\_load\_balancers](#output\_network\_load\_balancers) | FQDNs of Network Load Balancers. |
| <a name="output_vmseries_public_ips"></a> [vmseries\_public\_ips](#output\_vmseries\_public\_ips) | Map of public IPs created within `vmseries` module instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
