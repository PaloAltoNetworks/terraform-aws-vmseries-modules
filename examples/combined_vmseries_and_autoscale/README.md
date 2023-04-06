# VM-Series Auto Scaling example with VM-Series in target group for Gateway Load Balancer

A Terraform example for deploying VM-Series firewalls in an autoscaling group on AWS.
All VM-Series instances are automatically registered in target group for Gateway Load Balancer.
While bootstrapping of VM-Series, automatically there are made associations between VM-Series's subinteraces and GWLB endpoints.
Each VM-Series contains multiple network interfaces created by Lambda function.

## Topology

Code was prepared according to presented below diagram for *combined model*.

![](https://user-images.githubusercontent.com/9674179/229622544-0658b32a-3989-4bef-a770-287ee72fc88f.png)

## Prerequisites

1. Deploy Panorama e.g. by using [standalone Panorama example](../../examples/standalone_panorama)
2. Prepare device group, template, template stack in Panorama
3. Download and install plugin `sw_fw_license` for managing licences
4. Configure bootstrap definition and license manager
5. Configure [license API key](https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/license-the-vm-series-firewall/install-a-license-deactivation-api-key)
6. Configure VPC peering between VPC with Panorama and VPC with VM-Series in autoscaling group (after deploying that example)

## Usage

1. Copy `example.tfvars` into `terraform.tfvars`
2. Review `terraform.tfvars` file, especially with lines commented by ` # TODO: update here`
3. Initialize Terraform: `terraform init`
5. Prepare plan: `terraform plan`
6. Deploy infrastructure: `terraform apply -auto-approve`
7. Destroy infrastructure if needed: `terraform destroy -auto-approve`

## Lambda function

[Lambda function](../../modules/asg/lambda.py) is used to handle correct lifecycle action:
* instance launch or
* instance terminate

In case of creating VM-Series, there are performed below actions, which cannot be achieved in AWS launch template:
* change setting `source_dest_check` for first network interface (data plane)
* setup additional network interfaces (with optional possibility to attach EIP)

In case of destroying VM-Series, there is performed below action:
* clean EIP

Moreover having Lambda function executed while scaling out or in gives more options for extension e.g. delicesning VM-Series just after terminating instance.

## Autoscaling

[AWS Auto Scaling](https://aws.amazon.com/autoscaling/) monitors VM-Series and automatically adjusts capacity to maintain steady, predictable performance at the lowest possible cost. For autoscaling there are 10 metrics available from `vmseries` plugin:

- `DataPlaneCPUUtilizationPct`
- `DataPlanePacketBufferUtilization`
- `panGPGatewayUtilizationPct`
- `panGPGWUtilizationActiveTunnels`
- `panSessionActive`
- `panSessionConnectionsPerSecond`
- `panSessionSslProxyUtilization`
- `panSessionThroughputKbps`
- `panSessionThroughputPps`
- `panSessionUtilization`

Using that metrics there can be configured different [scaling plans](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscalingplans_scaling_plan). Below there are some examples, which can be used. All examples are based on target tracking configuration in scaling plan. Below code is already embedded into [asg module](../../modules/asg/main.tf):

```
  scaling_instruction {
    max_capacity       = var.max_size
    min_capacity       = var.min_size
    resource_id        = format("autoScalingGroup/%s", aws_autoscaling_group.this.name)
    scalable_dimension = "autoscaling:autoScalingGroup:DesiredCapacity"
    service_namespace  = "autoscaling"
    target_tracking_configuration {
      customized_scaling_metric_specification {
        metric_name = var.scaling_metric_name
        namespace   = var.scaling_cloudwatch_namespace
        statistic   = var.scaling_statistic
      }
      target_value = var.scaling_target_value
    }
  }
```

Using metrics from ``vmseries`` plugin we can defined multiple scaling configurations e.g.:

- based on number of active sessions:

```
scaling_metric_name          = "panSessionActive"
scaling_target_value         = 75
scaling_statistic            = "Average"
scaling_cloudwatch_namespace = "vmseries"
```

- based on data plane CPU utilization and average value above 75%:

```
scaling_metric_name          = "DataPlaneCPUUtilizationPct"
scaling_target_value         = 75
scaling_statistic            = "Average"
scaling_cloudwatch_namespace = "vmseries"
```

- based on data plane packet buffer utilization and max value above 80%

```
scaling_metric_name          = "DataPlanePacketBufferUtilization"
scaling_target_value         = 80
scaling_statistic            = "Maximum"
scaling_cloudwatch_namespace = "vmseries"
```

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
| <a name="module_app_lb"></a> [app\_lb](#module\_app\_lb) | ../../modules/nlb | n/a |
| <a name="module_gwlb"></a> [gwlb](#module\_gwlb) | ../../modules/gwlb | n/a |
| <a name="module_gwlbe_endpoint"></a> [gwlbe\_endpoint](#module\_gwlbe\_endpoint) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | PaloAltoNetworks/vmseries-modules/aws//modules/subnet_set | 0.4.1 |
| <a name="module_transit_gateway"></a> [transit\_gateway](#module\_transit\_gateway) | ../../modules/transit_gateway | n/a |
| <a name="module_transit_gateway_attachment"></a> [transit\_gateway\_attachment](#module\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_vm_series_asg"></a> [vm\_series\_asg](#module\_vm\_series\_asg) | ../../modules/asg | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | PaloAltoNetworks/vmseries-modules/aws//modules/vpc_route | 0.4.1 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_route.from_security_to_panorama](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.from_spokes_to_security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_iam_instance_profile.vm_series_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.vm_series_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vm_series_ec2_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.spoke_vms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_gwlb_endpoints"></a> [gwlb\_endpoints](#input\_gwlb\_endpoints) | A map defining GWLB endpoints.<br><br>Following properties are available:<br>- `name`: name of the GWLB endpoint<br>- `gwlb`: key of GWLB<br>- `vpc`: key of VPC<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic<br>- `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint<br><br>Example:<pre>gwlb_endpoints = {<br>  security_gwlb_eastwest = {<br>    name            = "eastwest-gwlb-endpoint"<br>    gwlb            = "security_gwlb"<br>    vpc             = "security_vpc"<br>    vpc_subnet      = "security_vpc-gwlbe_eastwest"<br>    act_as_next_hop = false<br>    to_vpc_subnets  = null<br>  }<br>}</pre> | <pre>map(object({<br>    name            = string<br>    gwlb            = string<br>    vpc             = string<br>    vpc_subnet      = string<br>    act_as_next_hop = bool<br>    to_vpc_subnets  = string<br>  }))</pre> | `{}` | no |
| <a name="input_gwlbs"></a> [gwlbs](#input\_gwlbs) | A map defining Gateway Load Balancers.<br><br>Following properties are available:<br>- `name`: name of the GWLB <br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br><br>Example:<pre>gwlbs = {<br>  security_gwlb = {<br>    name       = "security-gwlb"<br>    vpc_subnet = "security_vpc-gwlb"<br>  }<br>}</pre> | <pre>map(object({<br>    name       = string<br>    vpc_subnet = string<br>  }))</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_natgws"></a> [natgws](#input\_natgws) | A map defining NAT Gateways.<br><br>Following properties are available:<br>- `name`: name of NAT Gateway<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br><br>Example:<pre>natgws = {<br>  security_nat_gw = {<br>    name       = "natgw"<br>    vpc_subnet = "security_vpc-natgw"<br>  }<br>}</pre> | <pre>map(object({<br>    name       = string<br>    vpc_subnet = string<br>  }))</pre> | `{}` | no |
| <a name="input_panorama"></a> [panorama](#input\_panorama) | A object defining TGW attachment and CIDR for Panorama.<br><br>Following properties are available:<br>- `transit_gateway_attachment_id`: ID of attachment for Panorama<br>- `vpc_cidr`: CIDR of the VPC, where Panorama is deployed<br><br>Example:<pre>panorama = {<br>  transit_gateway_attachment_id = "tgw-attach-123456789"<br>  vpc_cidr                      = "10.255.0.0/24"<br>}</pre> | <pre>object({<br>    transit_gateway_attachment_id = string<br>    vpc_cidr                      = string<br>  })</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_spoke_lbs"></a> [spoke\_lbs](#input\_spoke\_lbs) | A map defining Network Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `vms`: keys of spoke VMs<br><br>Example:<pre>spoke_lbs = {<br>  "app1-nlb" = {<br>    vpc_subnet = "app1_vpc-app1_lb"<br>    vms        = ["app1_vm01", "app1_vm02"]<br>  }<br>}</pre> | <pre>map(object({<br>    vpc_subnet = string<br>    vms        = list(string)<br>  }))</pre> | `{}` | no |
| <a name="input_spoke_vms"></a> [spoke\_vms](#input\_spoke\_vms) | A map defining VMs in spoke VPCs.<br><br>Following properties are available:<br>- `az`: name of the Availability Zone<br>- `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `security_group`: security group assigned to ENI used by VM<br>- `type`: EC2 type VM<br><br>Example:<pre>spoke_vms = {<br>  "app1_vm01" = {<br>    az             = "eu-central-1a"<br>    vpc            = "app1_vpc"<br>    vpc_subnet     = "app1_vpc-app1_vm"<br>    security_group = "app1_vm"<br>    type           = "t2.micro"<br>  }<br>}</pre> | <pre>map(object({<br>    az             = string<br>    vpc            = string<br>    vpc_subnet     = string<br>    security_group = string<br>    type           = string<br>  }))</pre> | `{}` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_tgw"></a> [tgw](#input\_tgw) | A object defining Transit Gateway.<br><br>Following properties are available:<br>- `create`: set to false, if existing TGW needs to be reused<br>- `id`:  id of existing TGW or null<br>- `name`: name of TGW to create or use<br>- `asn`: ASN number<br>- `route_tables`: map of route tables<br>- `attachments`: map of TGW attachments<br><br>Example:<pre>tgw = {<br>  create = true<br>  id     = null<br>  name   = "tgw"<br>  asn    = "64512"<br>  route_tables = {<br>    "from_security_vpc" = {<br>      create = true<br>      name   = "from_security"<br>    }<br>  }<br>  attachments = {<br>    security = {<br>      name                = "vmseries"<br>      vpc_subnet          = "security_vpc-tgw_attach"<br>      route_table         = "from_security_vpc"<br>      propagate_routes_to = "from_spoke_vpc"<br>    }<br>  }<br>}</pre> | <pre>object({<br>    create = bool<br>    id     = string<br>    name   = string<br>    asn    = string<br>    route_tables = map(object({<br>      create = bool<br>      name   = string<br>    }))<br>    attachments = map(object({<br>      name                = string<br>      vpc_subnet          = string<br>      route_table         = string<br>      propagate_routes_to = string<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_vmseries_asgs"></a> [vmseries\_asgs](#input\_vmseries\_asgs) | A map defining Autoscaling Groups with VM-Series instances.<br><br>Following properties are available:<br>- `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama<br>- `panos_version`: PAN-OS version used for VM-Series<br>- `vpc`: key of VPC<br>- `gwlb`: key of GWLB<br>- `interfaces`: configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group <br>- `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints<br>- `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series<br>- `asg_desired_cap`: the number of Amazon EC2 instances that should be running in the group<br>- `asg_min_size`: minimum size of the Auto Scaling Group<br>- `asg_max_size`: maximum size of the Auto Scaling Group<br>- `lambda_vpc_subnet`: key of the VPC and subnet connected by '-' character, where Lambda is deployed<br>- `scaling_plan_enabled`: `true` if automatic dynamic scaling policy should be created<br>- `scaling_metric_name`: name of the metric used in dynamic scaling policy<br>- `scaling_tags`: tags configured for dynamic scaling policy<br>- `scaling_target_value`: target value for the metric used in dynamic scaling policy<br>- `scaling_cloudwatch_namespace`: name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)<br><br>Example:<pre>vmseries_asgs = {<br>  main_asg = {<br>    bootstrap_options = {<br>      mgmt-interface-swap         = "enable"<br>      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"<br>      panorama-server             = ""<br>      auth-key                    = ""<br>      dgname                      = ""<br>      tplname                     = ""<br>      dhcp-send-hostname          = "yes"<br>      dhcp-send-client-id         = "yes"<br>      dhcp-accept-server-hostname = "yes"<br>      dhcp-accept-server-domain   = "yes"<br>    }<br><br>    panos_version = "10.2.3"<br><br>    vpc  = "security_vpc"<br>    gwlb = "security_gwlb"<br><br>    interfaces = {<br>      private = {<br>        device_index   = 0<br>        security_group = "vmseries_private"<br>        subnet = {<br>          "privatea" = "eu-central-1a",<br>          "privateb" = "eu-central-1b"<br>        }<br>        create_public_ip  = false<br>        source_dest_check = false<br>      }<br>      mgmt = {<br>        device_index   = 1<br>        security_group = "vmseries_mgmt"<br>        subnet = {<br>          "mgmta" = "eu-central-1a",<br>          "mgmtb" = "eu-central-1b"<br>        }<br>        create_public_ip  = true<br>        source_dest_check = true<br>      }<br>      public = {<br>        device_index   = 2<br>        security_group = "vmseries_public"<br>        subnet = {<br>          "publica" = "eu-central-1a",<br>          "publicb" = "eu-central-1b"<br>        }<br>        create_public_ip  = false<br>        source_dest_check = false<br>      }<br>    }<br><br>    subinterfaces = {<br>      inbound1 = "ethernet1/1.11"<br>      inbound2 = "ethernet1/1.12"<br>      outbound = "ethernet1/1.20"<br>      eastwest = "ethernet1/1.30"<br>    }<br><br>    ebs_kms_id = "alias/aws/ebs"<br><br>    asg_desired_cap = 1<br>    asg_min_size    = 1<br>    asg_max_size    = 2<br><br>    lambda_vpc_subnet = "security_vpc-lambda"<br><br>    scaling_plan_enabled = true<br>    scaling_metric_name  = "panSessionActive"<br>    scaling_tags = {<br>      ManagedBy = "terraform"<br>    }<br>    scaling_target_value         = 75<br>    scaling_cloudwatch_namespace = "example-vmseries"<br>  }<br>}</pre> | <pre>map(object({<br>    bootstrap_options = object({<br>      mgmt-interface-swap         = string<br>      plugin-op-commands          = string<br>      panorama-server             = string<br>      auth-key                    = string<br>      dgname                      = string<br>      tplname                     = string<br>      dhcp-send-hostname          = string<br>      dhcp-send-client-id         = string<br>      dhcp-accept-server-hostname = string<br>      dhcp-accept-server-domain   = string<br>    })<br><br>    panos_version = string<br><br>    vpc  = string<br>    gwlb = string<br><br>    interfaces = map(object({<br>      device_index      = number<br>      security_group    = string<br>      subnet            = map(string)<br>      create_public_ip  = bool<br>      source_dest_check = bool<br>    }))<br><br>    subinterfaces = map(string)<br><br>    ebs_kms_id = string<br><br>    asg_desired_cap = number<br>    asg_min_size    = number<br>    asg_max_size    = number<br><br>    lambda_vpc_subnet = string<br><br>    scaling_plan_enabled         = bool<br>    scaling_metric_name          = string<br>    scaling_tags                 = map(string)<br>    scaling_target_value         = number<br>    scaling_cloudwatch_namespace = string<br>  }))</pre> | `{}` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br><br>Following properties are available:<br>- `name`: VPC name<br>- `cidr`: CIDR for VPC<br>- `security_groups`: map of security groups<br>- `subnets`: map of subnets<br><br>Example:<pre>vpcs = {<br>  example_vpc = {<br>    name = "example-spoke-vpc"<br>    cidr = "10.104.0.0/16"<br>    security_groups = {<br>      example_vm = {<br>        name = "example_vm"<br>        rules = {<br>          all_outbound = {<br>            description = "Permit All traffic outbound"<br>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>            cidr_blocks = ["0.0.0.0/0"]<br>          }<br>        }<br>      }<br>    }<br>    subnets = {<br>      "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm" }<br>      "10.104.128.0/24" = { az = "eu-central-1b", set = "vm" }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name = string<br>    cidr = string<br>    security_groups = map(object({<br>      name = string<br>      rules = map(object({<br>        description = string<br>        type        = string,<br>        from_port   = string<br>        to_port     = string,<br>        protocol    = string<br>        cidr_blocks = list(string)<br>      }))<br>    }))<br>    subnets = map(object({<br>      az  = string<br>      set = string<br>    }))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_inspected_dns_name"></a> [app\_inspected\_dns\_name](#output\_app\_inspected\_dns\_name) | FQDN of App Internal Load Balancer.<br>Can be used in VM-Series configuration to balance traffic between the application instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
