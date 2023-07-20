---
short_title: Isolated Design with Autoscaling
type: refarch
show_in_hub: true
---
# Reference Architecture with Terraform: VM-Series in AWS, Isolated Design Model, Common NGFW option with Autoscaling

Palo Alto Networks produces several [validated reference architecture design and deployment documentation guides](https://www.paloaltonetworks.com/resources/reference-architectures), which describe well-architected and tested deployments. When deploying VM-Series in a public cloud, the reference architectures guide users toward the best security outcomes, whilst reducing rollout time and avoiding common integration efforts.
The Terraform code presented here will deploy Palo Alto Networks VM-Series firewalls in AWS based on the centralized design; for a discussion of other options, please see the design guide from [the reference architecture guides](https://www.paloaltonetworks.com/resources/reference-architectures).

## Reference Architecture Design

![Simplified High Level Topology Diagram](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/assets/6574404/5199b4a8-2a59-4789-9ec0-870d97133acd)

This code implements:
- an _isolated design_, which secures outbound and inbound traffic flows using AWS Gateway Load Balancer (GWLB). Application resources are segmented across multiple VPCs that distribute traffic to the dedicated VPC for security services where the VM-Series are deployed.

## Detailed Architecture and Design

### Isolated Design
The Isolated Design model centralizes the security instances in a dedicated security VPC, while providing one or more isolated VPCs inbound and outbound security services. This design leverages a VPC dedicated to security. In the security VPC, you deploy the VM-Series firewalls, in separate availability zones, and a GWLB to distribute traffic to the firewalls. This design uses overlay routing for outbound security on the VM-Series firewalls. Outbound traffic from instances in the isolated VPCs uses the PrivateLink connections from GWLB endpoints in the applications. VPCs to the GWLB in the security VPC to egress the AWS environment through the VM-Series firewalls. 

Inbound traffic originates outside the VPC and is destined to applications or services hosted within your VPCs, such as web servers. This design uses the GWLB and VM-Series firewalls in the security VPC, with GWLB endpoints in the application VPCs for the transparent inspection of inbound traffic.

![](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/assets/9674179/06c9c5f3-eb4f-4636-bbbc-c45d0e8b0290)

### Auto Scaling VM-Series

Auto scaling: Public-cloud environments focus on scaling out a deployment instead of scaling up. This architectural difference stems primarily from the capability of public-cloud environments to dynamically increase or decrease the number of resources allocated to your environment. Using native AWS services like CloudWatch, auto scaling groups (ASG) and VM-Series automation features, the guide implements VM-Series that will scale in and out dynamically, as your protected workload demands fluctuate. The VM-Series firewalls are deployed in an auto scaling group, and are automatically registered to a Gateway Load Balancer. While bootstrapping the VM-Series, there are associations made automatically between VM-Series subinterfaces and the GWLB endpoints. Each VM-Series contains multiple network interfaces created by an AWS Lambda function.

## Prerequisites

The following steps should be followed before deploying the Terraform code presented here.

1. Deploy Panorama e.g. by using [Panorama example](../../examples/panorama_standalone)
2. Prepare device group, template, template stack in Panorama
3. Download and install plugin `sw_fw_license` for managing licenses
4. Configure bootstrap definition and license manager
5. Configure [license API key](https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/license-the-vm-series-firewall/install-a-license-deactivation-api-key)
6. Configure security rules and NAT rules for outbound traffic
7. Configure interface management profile to enable health checks from GWLB
8. Configure network interfaces and subinterfaces, zones and virtual router in template
9. Configure [static routes with path monitoring](https://docs.paloaltonetworks.com/pan-os/10-1/pan-os-networking-admin/static-routes/configure-path-monitoring-for-a-static-route)
<details><summary>Details</summary>
<p>
Using multiple template stacks, one for each AZ complicates autoscaling and the Panorama Licensing plugin configuration. The virtual router (VR) configuration combined with path monitoring outlined below avoids using AZ-specific template stacks and variables.

**Virtual Router Configuration**

1. Create static routes for all internally routed CIDRs
2. Set the next hop to the default gateway IP of the trust subnet of the corresponding availability zone, which the firewall is connected to.
3. Set a unique metric value per AZ so that it doesn't overlap with other routes with the same destinations.
4. Enable Path Monitoring for the route.
- Source IP: DHCP
- Destination IP: Next Hop IP of the subnet of the corresponding AZ.

The AWS NACL applied to the trust subnets blocks the path monitor from pinging default gateways of the trust subnets in the other availability zones. This will cause the firewall to remove all routes that don't apply to the Availability zone it is in.

Below there is shown example of VR configuration with static routes and path monitoring:

| Name | Destination | Next Hop | Metric | Path Monitor Destination IP |
|--------|--------|--------|--------|--------|
| app1_az1 | 10.104.0.0/16 | 10.100.1.1 | 11 | 10.100.1.1 |
| app2_az1 | 10.105.0.0/16 | 10.100.1.1 | 11 | 10.100.1.1 |
| app1_az2 | 10.104.0.0/16 | 10.100.65.1 | 12 | 10.100.65.1 |
| app2_az2 | 10.105.0.0/16 | 10.100.65.1 | 12 | 10.100.65.1 |
| health_az1 | 10.100.0.0/16 | 10.100.1.1 | 11 | 10.100.1.1 |
| health_az2 | 10.100.0.0/16 | 10.100.65.1 | 12 | 10.100.65.1 |
</p>

An example XML configuration snippet (for PANOS 10.2.3) of the described configuration can be found [here](template-asg-path-monitoring.xml), which after importing to Panorama, can be merged using the command:

```
load config partial mode merge from-xpath /config/devices/entry/template/entry[@name='asg'] to-xpath /config/devices/entry/template/entry[@name='asg'] from template-asg-path-monitoring.xml
```

</details> 
10. Configure VPC peering between VPC with Panorama and VPC with VM-Series in autoscaling group (after deploying that example)

## Usage

1. Copy `example.tfvars` into `terraform.tfvars`
2. Review `terraform.tfvars` file, especially with lines commented by ` # TODO: update here`
3. Initialize Terraform: `terraform init`
5. Prepare plan: `terraform plan`
6. Deploy infrastructure: `terraform apply -auto-approve`
7. Destroy infrastructure if needed: `terraform destroy -auto-approve`

## Additional Reading

### Lambda function

[Lambda function](../../modules/asg/lambda.py) is used to handle correct lifecycle action:
* instance launch or
* instance terminate

In case of creating VM-Series, there are performed below actions, which cannot be achieved in AWS launch template:
* change setting `source_dest_check` for first network interface (data plane)
* setup additional network interfaces (with optional possibility to attach EIP)

In case of destroying VM-Series, there is performed below action:
* clean EIP

Moreover having Lambda function executed while scaling out or in gives more options for extension e.g. delicesning VM-Series just after terminating instance.

### Autoscaling

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
metric_name  = "panSessionActive"
target_value = 75
statistic    = "Average"
```

- based on data plane CPU utilization and average value above 75%:

```
metric_name  = "DataPlaneCPUUtilizationPct"
target_value = 75
statistic    = "Average"
```

- based on data plane packet buffer utilization and max value above 80%

```
metric_name  = "DataPlanePacketBufferUtilization"
target_value = 80
statistic    = "Maximum"
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
| <a name="module_gwlb"></a> [gwlb](#module\_gwlb) | ../../modules/gwlb | n/a |
| <a name="module_gwlbe_endpoint"></a> [gwlbe\_endpoint](#module\_gwlbe\_endpoint) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_public_alb"></a> [public\_alb](#module\_public\_alb) | ../../modules/alb | n/a |
| <a name="module_public_nlb"></a> [public\_nlb](#module\_public\_nlb) | ../../modules/nlb | n/a |
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_vm_series_asg"></a> [vm\_series\_asg](#module\_vm\_series\_asg) | ../../modules/asg | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | ../../modules/vpc_route | n/a |

### Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.spoke_vm_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.vm_series_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.spoke_vm_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vm_series_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vm_series_ec2_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.spoke_vms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_vpc_peering_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_kms_alias.current_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_gwlb_endpoints"></a> [gwlb\_endpoints](#input\_gwlb\_endpoints) | A map defining GWLB endpoints.<br><br>Following properties are available:<br>- `name`: name of the GWLB endpoint<br>- `gwlb`: key of GWLB<br>- `vpc`: key of VPC<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic<br>- `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint<br><br>Example:<pre>gwlb_endpoints = {<br>  security_gwlb_eastwest = {<br>    name            = "eastwest-gwlb-endpoint"<br>    gwlb            = "security_gwlb"<br>    vpc             = "security_vpc"<br>    vpc_subnet      = "security_vpc-gwlbe_eastwest"<br>    act_as_next_hop = false<br>    to_vpc_subnets  = null<br>  }<br>}</pre> | <pre>map(object({<br>    name            = string<br>    gwlb            = string<br>    vpc             = string<br>    vpc_subnet      = string<br>    act_as_next_hop = bool<br>    to_vpc_subnets  = string<br>  }))</pre> | `{}` | no |
| <a name="input_gwlbs"></a> [gwlbs](#input\_gwlbs) | A map defining Gateway Load Balancers.<br><br>Following properties are available:<br>- `name`: name of the GWLB<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br><br>Example:<pre>gwlbs = {<br>  security_gwlb = {<br>    name       = "security-gwlb"<br>    vpc_subnet = "security_vpc-gwlb"<br>  }<br>}</pre> | <pre>map(object({<br>    name       = string<br>    vpc_subnet = string<br>  }))</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_panorama_connection"></a> [panorama\_connection](#input\_panorama\_connection) | A object defining VPC peering and CIDR for Panorama.<br><br>Following properties are available:<br>- `security_vpc`: key of the security VPC<br>- `peering_vpc_id`: ID of the VPC for Panorama<br>- `vpc_cidr`: CIDR of the VPC, where Panorama is deployed<br><br>Example:<pre>panorama = {<br>  security_vpc   = "security_vpc"<br>  peering_vpc_id = "vpc-1234567890"<br>  vpc_cidr       = "10.255.0.0/24"<br>}</pre> | <pre>object({<br>    security_vpc   = string<br>    peering_vpc_id = string<br>    vpc_cidr       = string<br>  })</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_spoke_albs"></a> [spoke\_albs](#input\_spoke\_albs) | A map defining Application Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `rules`: Rules defining the method of traffic balancing<br>- `vms`: Instances to be the target group for ALB<br>- `vpc`: The VPC in which the load balancer is to be run<br>- `vpc_subnet`: The subnets in which the Load Balancer is to be run<br>- `security_gropus`: Security Groups to be associated with the ALB<pre></pre> | <pre>map(object({<br>    rules           = any<br>    vms             = list(string)<br>    vpc             = string<br>    vpc_subnet      = string<br>    security_groups = string<br>  }))</pre> | n/a | yes |
| <a name="input_spoke_nlbs"></a> [spoke\_nlbs](#input\_spoke\_nlbs) | A map defining Network Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `vms`: keys of spoke VMs<br><br>Example:<pre>spoke_lbs = {<br>  "app1-nlb" = {<br>    vpc_subnet = "app1_vpc-app1_lb"<br>    vms        = ["app1_vm01", "app1_vm02"]<br>  }<br>}</pre> | <pre>map(object({<br>    vpc_subnet = string<br>    vms        = list(string)<br>  }))</pre> | `{}` | no |
| <a name="input_spoke_vms"></a> [spoke\_vms](#input\_spoke\_vms) | A map defining VMs in spoke VPCs.<br><br>Following properties are available:<br>- `az`: name of the Availability Zone<br>- `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `security_group`: security group assigned to ENI used by VM<br>- `type`: EC2 type VM<br><br>Example:<pre>spoke_vms = {<br>  "app1_vm01" = {<br>    az             = "eu-central-1a"<br>    vpc            = "app1_vpc"<br>    vpc_subnet     = "app1_vpc-app1_vm"<br>    security_group = "app1_vm"<br>    type           = "t2.micro"<br>  }<br>}</pre> | <pre>map(object({<br>    az             = string<br>    vpc            = string<br>    vpc_subnet     = string<br>    security_group = string<br>    type           = string<br>  }))</pre> | `{}` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_vmseries_asgs"></a> [vmseries\_asgs](#input\_vmseries\_asgs) | A map defining Autoscaling Groups with VM-Series instances.<br><br>Following properties are available:<br>- `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama<br>- `panos_version`: PAN-OS version used for VM-Series<br>- `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series<br>- `vpc`: key of VPC<br>- `gwlb`: key of GWLB<br>- `interfaces`: configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group<br>- `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints<br>- `asg`: the number of Amazon EC2 instances that should be running in the group (desired, minimum, maximum)<br>- `scaling_plan`: scaling plan with attributes<br>  - `enabled`: `true` if automatic dynamic scaling policy should be created<br>  - `metric_name`: name of the metric used in dynamic scaling policy<br>  - `target_value`: target value for the metric used in dynamic scaling policy<br>  - `statistic`: statistic of the metric. Valid values: Average, Maximum, Minimum, SampleCount, Sum<br>  - `cloudwatch_namespace`: name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)<br>  - `tags`: tags configured for dynamic scaling policy<br><br>Example:<pre>vmseries_asgs = {<br>  main_asg = {<br>    bootstrap_options = {<br>      mgmt-interface-swap         = "enable"<br>      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable" # TODO: update here<br>      panorama-server             = ""                                                                                   # TODO: update here<br>      auth-key                    = ""                                                                                   # TODO: update here<br>      dgname                      = ""                                                                                   # TODO: update here<br>      tplname                     = ""                                                                                   # TODO: update here<br>      dhcp-send-hostname          = "yes"                                                                                # TODO: update here<br>      dhcp-send-client-id         = "yes"                                                                                # TODO: update here<br>      dhcp-accept-server-hostname = "yes"                                                                                # TODO: update here<br>      dhcp-accept-server-domain   = "yes"                                                                                # TODO: update here<br>    }<br><br>    panos_version = "10.2.3"        # TODO: update here<br>    ebs_kms_id    = "alias/aws/ebs" # TODO: update here<br><br>    vpc               = "security_vpc"<br>    gwlb              = "security_gwlb"<br><br>    interfaces = {<br>      private = {<br>        device_index   = 0<br>        security_group = "vmseries_private"<br>        subnet = {<br>          "privatea" = "eu-central-1a",<br>          "privateb" = "eu-central-1b"<br>        }<br>        create_public_ip  = false<br>        source_dest_check = false<br>      }<br>      mgmt = {<br>        device_index   = 1<br>        security_group = "vmseries_mgmt"<br>        subnet = {<br>          "mgmta" = "eu-central-1a",<br>          "mgmtb" = "eu-central-1b"<br>        }<br>        create_public_ip  = true<br>        source_dest_check = true<br>      }<br>      public = {<br>        device_index   = 2<br>        security_group = "vmseries_public"<br>        subnet = {<br>          "publica" = "eu-central-1a",<br>          "publicb" = "eu-central-1b"<br>        }<br>        create_public_ip  = false<br>        source_dest_check = false<br>      }<br>    }<br><br>    subinterfaces = {<br>      inbound = {<br>        app1 = {<br>          gwlb_endpoint = "app1_inbound"<br>          subinterface  = "ethernet1/1.11"<br>        }<br>        app2 = {<br>          gwlb_endpoint = "app2_inbound"<br>          subinterface  = "ethernet1/1.12"<br>        }<br>      }<br>      outbound = {<br>        only_1_outbound = {<br>          gwlb_endpoint = "security_gwlb_outbound"<br>          subinterface  = "ethernet1/1.20"<br>        }<br>      }<br>      eastwest = {<br>        only_1_eastwest = {<br>          gwlb_endpoint = "security_gwlb_eastwest"<br>          subinterface  = "ethernet1/1.30"<br>        }<br>      }<br>    }<br><br>    asg = {<br>      desired_cap = 2<br>      min_size    = 2<br>      max_size    = 4<br>    }<br><br>    scaling_plan = {<br>      enabled              = true               # TODO: update here<br>      metric_name          = "panSessionActive" # TODO: update here<br>      target_value         = 75                 # TODO: update here<br>      statistic            = "Average"          # TODO: update here<br>      cloudwatch_namespace = "example-vmseries" # TODO: update here<br>      tags = {<br>        ManagedBy = "terraform"<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    bootstrap_options = object({<br>      mgmt-interface-swap         = string<br>      plugin-op-commands          = string<br>      panorama-server             = string<br>      auth-key                    = string<br>      dgname                      = string<br>      tplname                     = string<br>      dhcp-send-hostname          = string<br>      dhcp-send-client-id         = string<br>      dhcp-accept-server-hostname = string<br>      dhcp-accept-server-domain   = string<br>    })<br><br>    panos_version = string<br>    ebs_kms_id    = string<br><br>    vpc  = string<br>    gwlb = string<br><br>    interfaces = map(object({<br>      device_index      = number<br>      security_group    = string<br>      subnet            = map(string)<br>      create_public_ip  = bool<br>      source_dest_check = bool<br>    }))<br><br>    subinterfaces = map(map(object({<br>      gwlb_endpoint = string<br>      subinterface  = string<br>    })))<br><br>    asg = object({<br>      desired_cap = number<br>      min_size    = number<br>      max_size    = number<br>    })<br><br>    scaling_plan = object({<br>      enabled              = bool<br>      metric_name          = string<br>      target_value         = number<br>      statistic            = string<br>      cloudwatch_namespace = string<br>      tags                 = map(string)<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br><br>Following properties are available:<br>- `name`: VPC name<br>- `cidr`: CIDR for VPC<br>- `nacls`: map of network ACLs<br>- `security_groups`: map of security groups<br>- `subnets`: map of subnets with properties:<br>   - `az`: availability zone<br>   - `set`: internal identifier referenced by main.tf<br>   - `nacl`: key of NACL (can be null)<br>- `routes`: map of routes with properties:<br>   - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`<br>   - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources<br>   - `next_hop_type` - internet\_gateway, nat\_gateway, transit\_gateway\_attachment or gwlbe\_endpoint<br><br>Example:<pre>vpcs = {<br>  example_vpc = {<br>    name = "example-spoke-vpc"<br>    cidr = "10.104.0.0/16"<br>    nacls = {<br>      trusted_path_monitoring = {<br>        name               = "trusted-path-monitoring"<br>        rules = {<br>          allow_inbound = {<br>            rule_number = 300<br>            egress      = false<br>            protocol    = "-1"<br>            rule_action = "allow"<br>            cidr_block  = "0.0.0.0/0"<br>            from_port   = null<br>            to_port     = null<br>          }<br>        }<br>      }<br>    }<br>    security_groups = {<br>      example_vm = {<br>        name = "example_vm"<br>        rules = {<br>          all_outbound = {<br>            description = "Permit All traffic outbound"<br>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>            cidr_blocks = ["0.0.0.0/0"]<br>          }<br>        }<br>      }<br>    }<br>    subnets = {<br>      "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }<br>      "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }<br>    }<br>    routes = {<br>      vm_default = {<br>        vpc_subnet    = "app1_vpc-app1_vm"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1"<br>        next_hop_type = "transit_gateway_attachment"<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name = string<br>    cidr = string<br>    nacls = map(object({<br>      name = string<br>      rules = map(object({<br>        rule_number = number<br>        egress      = bool<br>        protocol    = string<br>        rule_action = string<br>        cidr_block  = string<br>        from_port   = string<br>        to_port     = string<br>      }))<br>    }))<br>    security_groups = map(object({<br>      name = string<br>      rules = map(object({<br>        description = string<br>        type        = string,<br>        from_port   = string<br>        to_port     = string,<br>        protocol    = string<br>        cidr_blocks = list(string)<br>      }))<br>    }))<br>    subnets = map(object({<br>      az   = string<br>      set  = string<br>      nacl = string<br>    }))<br>    routes = map(object({<br>      vpc_subnet    = string<br>      to_cidr       = string<br>      next_hop_key  = string<br>      next_hop_type = string<br>    }))<br>  }))</pre> | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_load_balancers"></a> [application\_load\_balancers](#output\_application\_load\_balancers) | FQDNs of Application Load Balancers |
| <a name="output_network_load_balancers"></a> [network\_load\_balancers](#output\_network\_load\_balancers) | FQDNs of Network Load Balancers. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
