# Palo Alto Networks Elastic Load Balancer (ALB / NLB) Module for AWS

## Overview  

This module creates ELB resources in AWS that are intended to integrate with VM-Series load balancer "sandwich" deployments for securing inbound traffic to public-facing applications. This module supports both Application Load Balancers (ALB) or Network Load Balancers (NLB).

The ELBs and associated applications are defined in variables as nested maps, with some optional parameters which are described here.

Each application is defined separately and the inbound traffic towards it will be forwarded to the VM-Series firewalls on a unique target group and port. These unique ports will be used by VM-Series to distinguish different applications and apply NAT policies to forward traffic to the appropriate backend destination.

This module assumes a existing VPC with existing VM-Series instance(s). For this deployment model, the VM-Series should typically be provisioned using [Management Interface Swap](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/launch-the-vm-series-firewall-on-aws.html), so that the default interface of the instance (eth0) can accept traffic and be used as a member of the ELB target group.


## Usage

See examples for more details of usage.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.29, <0.15 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.18 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.18 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_lb.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_albs"></a> [albs](#input\_albs) | Nested Map of Application Load balancers to create and the apps associated with each. See README for details. | `map(any)` | `{}` | no |
| <a name="input_elb_subnet_ids"></a> [elb\_subnet\_ids](#input\_elb\_subnet\_ids) | List of Subnet IDs to be used as targets for all ELBs | `list(string)` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Map of tags (key / value pairs) to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_nlbs"></a> [nlbs](#input\_nlbs) | Nested Map of AWS Network Load balancers to create and the "apps" (target groups, listeners) associated with each.<br><br>-> nlb map key (string) :  Unique reference for each NLB. Only used to reference resources inside of terraform<br>--> `name` (string) : Name of NLB (ELB Names in AWS are not tag based, changing name is destructive)<br>--> `internal` (bool) : Default `false`. Set to `true` to create a private-only NLB.<br>--> `enable_cross_zone_load_balancing` (bool) :  Set to true to enable each front-end to send traffic to all targets ()<br>--> `eips` (bool) : Set `true` to create static EIPs for the NLB<br>--> `apps` (map) :  Nested map of "apps" associated with this NLB<br>---> apps map key (string) :  Unique reference for each app of this NLB. Only used to reference resources inside of terraform<br>----> `name` (string) : Name Tag for the Target Group<br>----> `protocol` (string) : `TCP`, `TLS`, `UDP`, or `TCP_UDP`<br>----> `listener_port` (string) :  Port for the NLB listener<br>----> `target_port` (string) :  Port for the target group for VM-Series translation. Typically will be unique per app<br><br>Example:<pre>nlbs = {<br>  nlb01 = {<br>    name                             = "nlb01-inbound"<br>    internal                         = false<br>    eips                             = true<br>    enable_cross_zone_load_balancing = true<br>    apps = {<br>      app01 = {<br>        name          = "inbound-nlb01-app01-ssh"<br>        protocol      = "TCP"<br>        listener_port = "22"<br>        target_port   = "5001"<br>      }<br>      app02 = {<br>        name          = "inbound-nlb01-app02-https"<br>        protocol      = "TCP"<br>        listener_port = "443"<br>        target_port   = "5002"<br>      }<br>    }<br>  }</pre> | `map(any)` | `{}` | no |
| <a name="input_target_instance_ids"></a> [target\_instance\_ids](#input\_target\_instance\_ids) | List of Instance IDs of VM-Series (with interface swap enabled) to be used as targets for all ELBs | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Identifier of the pre-existing VPC to create the ELB resources in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns"></a> [alb\_dns](#output\_alb\_dns) | Map of DNS Names for each ALB |
| <a name="output_albs"></a> [albs](#output\_albs) | Full output of all ALBs |
| <a name="output_nlb_dns"></a> [nlb\_dns](#output\_nlb\_dns) | Map of DNS Names for each NLB |
| <a name="output_nlb_eips"></a> [nlb\_eips](#output\_nlb\_eips) | Map of EIPs created for NLBs |
| <a name="output_nlbs"></a> [nlbs](#output\_nlbs) | Full output of all NLBs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Nested Map Input Variable Definitions

For each of the nested map variables, the key of each map will be the terraform state resource identifier within terraform and must be unique, but is not used for resource naming.

### albs

The `albs` variable is a map of maps, where each map represents an Application Load Balancer. Create a unique top level key for each ALB to be defined.

Each alb map inside of `albs` has the following inputs available (See examples folder for additional references):

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-------:|:-----:|
| name | Name of ALB (ELB Names in AWS are not tag based, changing name is destructive)  | string | - | yes |
| internal | Set false for public NLB (typical for VM-Series deployment) | bool | `false` | no |
| http_listener | Flag to create HTTP listener | bool | `false` | no |
| http_listener_port | Port of HTTP Listener | string | - |  yes if `http_listener == true`|
| https_listener | Flag to create HTTPS listener | bool | `false` | no |
| https_listener_port | Port of HTTPS Listener | string | - |  yes if `https_listener == true`|
| default_certificate_arn | ARN of defualt certificate for this ALB | string | - | yes if `https_listener == true`|
| additional_certificate_arns | ARNs of additional certificates | list(string) | - | no |
| security_groups | Existing Security Group IDs to be applied to this ALB | list(string) | - | no |
| apps | Nested Map for app definitions (see below)  | map | {} | no |


### albs -> apps

The `apps` parameter inside of each `alb` is another nested map, where each map represents an application that is associated with the ALB. Create a unique top level key for each application to be defined.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-------:|:-----:|
| name | Name Tag for the Target Group  | string | - | yes |
| listener_protocol | Protocol of listener `HTTP` or `HTTPS` | string | - | yes |
| target_protocol | Protocol of target `HTTP` or `HTTPS` | string | - |  yes |
| target_port | Port for the target group for VM-Series translation. Typically will be unique per app | string | - | yes |
| rule_type | Type of rule `host_header` or `path` | string | - |  yes |
| rule_patterns | Patterns for the rule | list(string) | - | yes |
