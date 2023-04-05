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
| <a name="module_app1_gwlbe_inbound"></a> [app1\_gwlbe\_inbound](#module\_app1\_gwlbe\_inbound) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_app1_lb"></a> [app1\_lb](#module\_app1\_lb) | ../../modules/nlb | n/a |
| <a name="module_app1_route"></a> [app1\_route](#module\_app1\_route) | ../../modules/vpc_route | n/a |
| <a name="module_app1_subnet_sets"></a> [app1\_subnet\_sets](#module\_app1\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_app1_transit_gateway_attachment"></a> [app1\_transit\_gateway\_attachment](#module\_app1\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_app1_vpc"></a> [app1\_vpc](#module\_app1\_vpc) | ../../modules/vpc | n/a |
| <a name="module_app2_gwlbe_inbound"></a> [app2\_gwlbe\_inbound](#module\_app2\_gwlbe\_inbound) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_app2_lb"></a> [app2\_lb](#module\_app2\_lb) | ../../modules/nlb | n/a |
| <a name="module_app2_route"></a> [app2\_route](#module\_app2\_route) | ../../modules/vpc_route | n/a |
| <a name="module_app2_subnet_sets"></a> [app2\_subnet\_sets](#module\_app2\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_app2_transit_gateway_attachment"></a> [app2\_transit\_gateway\_attachment](#module\_app2\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_app2_vpc"></a> [app2\_vpc](#module\_app2\_vpc) | ../../modules/vpc | n/a |
| <a name="module_gwlbe_eastwest"></a> [gwlbe\_eastwest](#module\_gwlbe\_eastwest) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_gwlbe_outbound"></a> [gwlbe\_outbound](#module\_gwlbe\_outbound) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_security_gwlb"></a> [security\_gwlb](#module\_security\_gwlb) | ../../modules/gwlb | n/a |
| <a name="module_security_subnet_sets"></a> [security\_subnet\_sets](#module\_security\_subnet\_sets) | PaloAltoNetworks/vmseries-modules/aws//modules/subnet_set | 0.4.1 |
| <a name="module_security_transit_gateway_attachment"></a> [security\_transit\_gateway\_attachment](#module\_security\_transit\_gateway\_attachment) | ../../modules/transit_gateway_attachment | n/a |
| <a name="module_security_vpc"></a> [security\_vpc](#module\_security\_vpc) | ../../modules/vpc | n/a |
| <a name="module_security_vpc_routes"></a> [security\_vpc\_routes](#module\_security\_vpc\_routes) | PaloAltoNetworks/vmseries-modules/aws//modules/vpc_route | 0.4.1 |
| <a name="module_transit_gateway"></a> [transit\_gateway](#module\_transit\_gateway) | ../../modules/transit_gateway | n/a |
| <a name="module_vm_series_asg"></a> [vm\_series\_asg](#module\_vm\_series\_asg) | ../../modules/asg | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_route.from_security_to_panorama](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.from_spokes_to_security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_iam_instance_profile.vm_series_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.vm_series_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vm_series_ec2_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.app1_vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.app2_vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app1_gwlb_endpoint_set_name"></a> [app1\_gwlb\_endpoint\_set\_name](#input\_app1\_gwlb\_endpoint\_set\_name) | The name of the GWLB VPC Endpoint created to inspect traffic inbound from Internet to the app1 load balancer. | `string` | n/a | yes |
| <a name="input_app1_transit_gateway_attachment_name"></a> [app1\_transit\_gateway\_attachment\_name](#input\_app1\_transit\_gateway\_attachment\_name) | The name of the TGW Attachment to be created inside the app1 VPC. | `string` | n/a | yes |
| <a name="input_app1_vm_type"></a> [app1\_vm\_type](#input\_app1\_vm\_type) | EC2 type for "app1" VMs. | `string` | `"t2.micro"` | no |
| <a name="input_app1_vms"></a> [app1\_vms](#input\_app1\_vms) | Definition of an example "app1" application VMs. They are based on the latest version of Bitnami's NGINX image.<br>The structure of this map is similar to the one defining VM-Series, only one property is supported though: the Availability Zone the VM should be placed in.<br>Example:<pre>app_vms = {<br>  "appvm01" = { az = "us-east-1b" }<br>  "appvm02" = { az = "us-east-1a" }<br>}</pre> | `map(any)` | n/a | yes |
| <a name="input_app1_vpc_cidr"></a> [app1\_vpc\_cidr](#input\_app1\_vpc\_cidr) | The primary IPv4 CIDR of the created app1 VPC. | `string` | n/a | yes |
| <a name="input_app1_vpc_name"></a> [app1\_vpc\_name](#input\_app1\_vpc\_name) | The name tag of the created app1 VPC. | `string` | n/a | yes |
| <a name="input_app1_vpc_security_groups"></a> [app1\_vpc\_security\_groups](#input\_app1\_vpc\_security\_groups) | Map of security groups in app1 VPC | `any` | n/a | yes |
| <a name="input_app1_vpc_subnets"></a> [app1\_vpc\_subnets](#input\_app1\_vpc\_subnets) | Map of subnets in app1 VPC | `any` | n/a | yes |
| <a name="input_app2_gwlb_endpoint_set_name"></a> [app2\_gwlb\_endpoint\_set\_name](#input\_app2\_gwlb\_endpoint\_set\_name) | The name of the GWLB VPC Endpoint created to inspect traffic inbound from Internet to the app2 load balancer. | `string` | n/a | yes |
| <a name="input_app2_transit_gateway_attachment_name"></a> [app2\_transit\_gateway\_attachment\_name](#input\_app2\_transit\_gateway\_attachment\_name) | The name of the TGW Attachment to be created inside the app2 VPC. | `string` | n/a | yes |
| <a name="input_app2_vm_type"></a> [app2\_vm\_type](#input\_app2\_vm\_type) | EC2 type for "app2" VMs. | `string` | `"t2.micro"` | no |
| <a name="input_app2_vms"></a> [app2\_vms](#input\_app2\_vms) | Definition of an example "app2" application VMs. They are based on the latest version of Bitnami's NGINX image.<br>The structure of this map is similar to the one defining VM-Series, only one property is supported though: the Availability Zone the VM should be placed in.<br>Example:<pre>app_vms = {<br>  "appvm01" = { az = "us-east-1b" }<br>  "appvm02" = { az = "us-east-1a" }<br>}</pre> | `map(any)` | n/a | yes |
| <a name="input_app2_vpc_cidr"></a> [app2\_vpc\_cidr](#input\_app2\_vpc\_cidr) | The primary IPv4 CIDR of the created app2 VPC. | `string` | n/a | yes |
| <a name="input_app2_vpc_name"></a> [app2\_vpc\_name](#input\_app2\_vpc\_name) | The name tag of the created app2 VPC. | `string` | n/a | yes |
| <a name="input_app2_vpc_security_groups"></a> [app2\_vpc\_security\_groups](#input\_app2\_vpc\_security\_groups) | Map of security groups in app1 VPC | `any` | n/a | yes |
| <a name="input_app2_vpc_subnets"></a> [app2\_vpc\_subnets](#input\_app2\_vpc\_subnets) | Map of subnets in app1 VPC | `any` | n/a | yes |
| <a name="input_asg_desired_cap"></a> [asg\_desired\_cap](#input\_asg\_desired\_cap) | The number of Amazon EC2 instances that should be running in the group | `number` | n/a | yes |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | Maximum size of the Auto Scaling Group | `number` | n/a | yes |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | Minimum size of the Auto Scaling Group | `number` | n/a | yes |
| <a name="input_ebs_kms_id"></a> [ebs\_kms\_id](#input\_ebs\_kms\_id) | Alias for AWS KMS used for EBS encryption in VM-Series | `string` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_gwlb_endpoint_set_eastwest_name"></a> [gwlb\_endpoint\_set\_eastwest\_name](#input\_gwlb\_endpoint\_set\_eastwest\_name) | Name of the set with GWLB endpoints for east-west traffic | `string` | n/a | yes |
| <a name="input_gwlb_endpoint_set_outbound_name"></a> [gwlb\_endpoint\_set\_outbound\_name](#input\_gwlb\_endpoint\_set\_outbound\_name) | Name of the set with GWLB endpoints for outbound traffic | `string` | n/a | yes |
| <a name="input_gwlb_name"></a> [gwlb\_name](#input\_gwlb\_name) | Name of the GWLB | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | Name of the NAT gateway | `string` | n/a | yes |
| <a name="input_panorama_transit_gateway_attachment_id"></a> [panorama\_transit\_gateway\_attachment\_id](#input\_panorama\_transit\_gateway\_attachment\_id) | ID of TGW attachment for Panorama | `string` | `null` | no |
| <a name="input_panorama_vpc_cidr"></a> [panorama\_vpc\_cidr](#input\_panorama\_vpc\_cidr) | IPv4 CIDR of the VPC for Panorama | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_scaling_cloudwatch_namespace"></a> [scaling\_cloudwatch\_namespace](#input\_scaling\_cloudwatch\_namespace) | Name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS) | `string` | n/a | yes |
| <a name="input_scaling_metric_name"></a> [scaling\_metric\_name](#input\_scaling\_metric\_name) | Name of the metric used in dynamic scaling policy | `string` | n/a | yes |
| <a name="input_scaling_plan_enabled"></a> [scaling\_plan\_enabled](#input\_scaling\_plan\_enabled) | True, if automatic dynamic scaling policy should be created | `bool` | n/a | yes |
| <a name="input_scaling_tags"></a> [scaling\_tags](#input\_scaling\_tags) | Tags configured for dynamic scaling policy | `any` | n/a | yes |
| <a name="input_scaling_target_value"></a> [scaling\_target\_value](#input\_scaling\_target\_value) | Target value for the metric used in dynamic scaling policy | `number` | n/a | yes |
| <a name="input_security_vpc_cidr"></a> [security\_vpc\_cidr](#input\_security\_vpc\_cidr) | IPv4 CIDR for the security VPC | `string` | n/a | yes |
| <a name="input_security_vpc_mgmt_routes_to_tgw"></a> [security\_vpc\_mgmt\_routes\_to\_tgw](#input\_security\_vpc\_mgmt\_routes\_to\_tgw) | The eastwest inspection of traffic heading to VM-Series management interface is not possible.<br>Due to AWS own limitations, anything from the TGW destined for the management interface could *not* possibly override LocalVPC route.<br>Henceforth no management routes go back to gwlbe\_eastwest. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_name"></a> [security\_vpc\_name](#input\_security\_vpc\_name) | Name of the security VPC | `string` | n/a | yes |
| <a name="input_security_vpc_routes_eastwest_cidrs"></a> [security\_vpc\_routes\_eastwest\_cidrs](#input\_security\_vpc\_routes\_eastwest\_cidrs) | From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing back to TGW.<br>A list of strings, for example `[\"10.0.0.0/8\"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_destin_cidrs"></a> [security\_vpc\_routes\_outbound\_destin\_cidrs](#input\_security\_vpc\_routes\_outbound\_destin\_cidrs) | From the perspective of Security VPC, the destination addresses of packets coming from TGW and flowing outside.<br>A list of strings, for example `[\"0.0.0.0/0\"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_routes_outbound_source_cidrs"></a> [security\_vpc\_routes\_outbound\_source\_cidrs](#input\_security\_vpc\_routes\_outbound\_source\_cidrs) | From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing outside.<br>Used for return traffic routes post-inspection.<br>A list of strings, for example `[\"10.0.0.0/8\"]`. | `list(string)` | n/a | yes |
| <a name="input_security_vpc_security_groups"></a> [security\_vpc\_security\_groups](#input\_security\_vpc\_security\_groups) | Map of security groups configured in the security VPC e.g.:<br><br>security\_vpc\_security\_groups = {<br>  vmseries\_data = {<br>    name = "vmseries\_data"<br>    rules = {<br>      all\_outbound = {<br>        description = "Permit All traffic outbound"<br>        type        = "egress", from\_port = "0", to\_port = "0", protocol = "-1"<br>        cidr\_blocks = ["0.0.0.0/0"]<br>      }<br>      geneve = {<br>        description = "Permit GENEVE to GWLB subnets"<br>        type        = "ingress", from\_port = "6081", to\_port = "6081", protocol = "udp"<br>        cidr\_blocks = [<br>          "10.100.5.0/24", "10.100.69.0/24", "10.100.132.0/24", "10.100.201.0/24", "10.100.6.0/24", "10.100.70.0/24"<br>        ]<br>      }<br>      health\_probe = {<br>        description = "Permit Port 80 Health Probe to GWLB subnets"<br>        type        = "ingress", from\_port = "80", to\_port = "80", protocol = "tcp"<br>        cidr\_blocks = [<br>          "10.100.5.0/24", "10.100.69.0/24", "10.100.132.0/24", "10.100.201.0/24", "10.100.6.0/24", "10.100.70.0/24"<br>        ]<br>      }<br>    }<br>  }<br>} | `any` | n/a | yes |
| <a name="input_security_vpc_subnets"></a> [security\_vpc\_subnets](#input\_security\_vpc\_subnets) | Map of subnets configured in the security VPC e.g.: <br><br>security\_vpc\_subnets = {<br>  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.<br>  "10.100.0.0/24"  = { az = "eu-central-1a", set = "mgmt" }<br>  "10.100.64.0/24" = { az = "eu-central-1b", set = "mgmt" }<br>  "10.100.1.0/24"  = { az = "eu-central-1a", set = "data1" }<br>  "10.100.65.0/24" = { az = "eu-central-1b", set = "data1" }<br>  "10.100.3.0/24"  = { az = "eu-central-1a", set = "tgw\_attach" }<br>  "10.100.67.0/24" = { az = "eu-central-1b", set = "tgw\_attach" }<br>  "10.100.4.0/24"  = { az = "eu-central-1a", set = "gwlbe\_outbound" }<br>  "10.100.68.0/24" = { az = "eu-central-1b", set = "gwlbe\_outbound" }<br>  "10.100.5.0/24"  = { az = "eu-central-1a", set = "gwlb" }<br>  "10.100.69.0/24" = { az = "eu-central-1b", set = "gwlb" }<br>  "10.100.10.0/24" = { az = "eu-central-1a", set = "gwlbe\_eastwest" }<br>  "10.100.74.0/24" = { az = "eu-central-1b", set = "gwlbe\_eastwest" }<br>  "10.100.11.0/24" = { az = "eu-central-1a", set = "natgw" }<br>  "10.100.75.0/24" = { az = "eu-central-1b", set = "natgw" }<br>  "10.100.12.0/24" = { az = "eu-central-1a", set = "lambda" }<br>  "10.100.76.0/24" = { az = "eu-central-1b", set = "lambda" }<br>} | `any` | n/a | yes |
| <a name="input_security_vpc_tgw_attachment_name"></a> [security\_vpc\_tgw\_attachment\_name](#input\_security\_vpc\_tgw\_attachment\_name) | Name of TGW attachment for the security VPC | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_transit_gateway_asn"></a> [transit\_gateway\_asn](#input\_transit\_gateway\_asn) | Private Autonomous System Number (ASN) of the Transit Gateway for the Amazon side of a BGP session.<br>The range is 64512 to 65534 for 16-bit ASNs and 4200000000 to 4294967294 for 32-bit ASNs. | `number` | n/a | yes |
| <a name="input_transit_gateway_create"></a> [transit\_gateway\_create](#input\_transit\_gateway\_create) | False if using existing TGW, true if new TGW needs to be created | `bool` | `true` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the existing Transit Gateway. | `string` | `null` | no |
| <a name="input_transit_gateway_name"></a> [transit\_gateway\_name](#input\_transit\_gateway\_name) | The name tag of the created Transit Gateway. | `string` | n/a | yes |
| <a name="input_transit_gateway_route_tables"></a> [transit\_gateway\_route\_tables](#input\_transit\_gateway\_route\_tables) | Complex input with the Route Tables of the Transit Gateway. Example:<pre>{<br>  "from_security_vpc" = {<br>    create = true<br>    name   = "myrt1"<br>  }<br>  "from_spoke_vpc" = {<br>    create = true<br>    name   = "myrt2"<br>  }<br>}</pre>Two keys are required:<br><br>- from\_security\_vpc describes which route table routes the traffic coming from the Security VPC,<br>- from\_spoke\_vpc describes which route table routes the traffic coming from the Spoke (app1, app2) VPC.<br><br>Each of these entries can specify `create = true` which creates a new RT with a `name`.<br>With `create = false` the pre-existing RT named `name` is used. | `any` | n/a | yes |
| <a name="input_vmseries_common"></a> [vmseries\_common](#input\_vmseries\_common) | Common VM-Seriess like bootstrap options or network subinterfaces used to map with GWLB endpoints e.g.:<br><br>vmseries\_common = {<br>  bootstrap\_options = {<br>    mgmt-interface-swap = "enable"<br>    plugin-op-commands  = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"<br>    panorama-server     = ""<br>    auth-key            = ""<br>    dgname              = "example"<br>    tplname             = "example-stack"<br>  }<br>  subinterfaces = {<br>    inbound1 = "ethernet1/1.11"<br>    inbound2 = "ethernet1/1.12"<br>    outbound = "ethernet1/1.20"<br>    eastwest = "ethernet1/1.30"<br>  }<br>} | `any` | n/a | yes |
| <a name="input_vmseries_interfaces"></a> [vmseries\_interfaces](#input\_vmseries\_interfaces) | Configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group e.g.:<br><br>vmseries\_interfaces = {<br>  data1 = {<br>    device\_index   = 0<br>    security\_group = "vmseries\_data"<br>    subnet = {<br>      "data1a" = "eu-central-1a",<br>      "data1b" = "eu-central-1b"<br>    }<br>    source\_dest\_check = false<br>  }<br>  mgmt = {<br>    device\_index   = 1<br>    security\_group = "vmseries\_mgmt"<br>    subnet = {<br>      "mgmta" = "eu-central-1a",<br>      "mgmtb" = "eu-central-1b"<br>    }<br>    create\_public\_ip  = true<br>    source\_dest\_check = true<br>  }<br>} | `any` | n/a | yes |
| <a name="input_vmseries_version"></a> [vmseries\_version](#input\_vmseries\_version) | PAN-OS version used for VM-Series | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app1_inspected_dns_name"></a> [app1\_inspected\_dns\_name](#output\_app1\_inspected\_dns\_name) | FQDN of "app1" Internal Load Balancer.<br>Can be used in VM-Series configuration to balance traffic between the application instances. |
| <a name="output_app2_inspected_dns_name"></a> [app2\_inspected\_dns\_name](#output\_app2\_inspected\_dns\_name) | FQDN of "app2" Internal Load Balancer.<br>Can be used in VM-Series configuration to balance traffic between the application instances. |
| <a name="output_security_gwlb_service_name"></a> [security\_gwlb\_service\_name](#output\_security\_gwlb\_service\_name) | The AWS Service Name of the created GWLB, which is suitable to use for subsequent VPC Endpoints. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
