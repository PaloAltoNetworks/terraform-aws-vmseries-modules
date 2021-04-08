# Palo Alto Networks lastic Load Balancer (ALB / NLB) Module for AWS

## Overview  

Create ELB resources on AWS for ingress "load balancer sandwich" VM-Series deployments. Can create either public Application Load Balancers and / or Network Load balancers for use in inbound applications. Each inbound application is defined separately and will be forwarded to the VM-Series firewalls on a unique target group and port.

Load balancers and Applications are defined in nested map variables, with optional parameters defined here.

Assumes existing VPC with VM-Series instances deployed using interface swap mechanism so that default eth0 interfaces are in public subnets.


## Usage

See examples for more details of usage.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
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
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Map of tags (key / value pairs) to apply to all AWS resources | `map(string)` | `{}` | no |
| <a name="input_nlbs"></a> [nlbs](#input\_nlbs) | Nested Map of AWS Network Load balancers to create and the "apps" (target groups, listeners) associated with each.<br><br>- `key` (string) :  Unique reference for each NLB. Only used to reference resources inside of terraform<br>- `name` (string) : Name of NLB (ELB Names in AWS are not tag based, changing name is destructive)<br>- `internal` (bool) : Default `false`. Set false for public NLB (typical for VM-Series deployment)<br>- `enable_cross_zone_load_balancing` (bool) :  Set to true to enable each front-end to send traffic to all targets ()<br>- `eips` (bool) : Set `true` to create static EIPs for the NLB<br>- `apps` (map) :  Nested map of "apps" associated with this NLB<br>--> `key` (string) :  Unique reference for each app of this NLB. Only used to reference resources inside of terraform<br>--> `name` (string) : Name Tag for the Target Group<br>--> `protocol` (string) : `TCP`, `TLS`, `UDP`, or `TCP_UDP`<br>--> `listener_port` (string) :  Port for the NLB listener<br>--> `target_port` (string) :  Port for the target group for VM-Series translation. Typically will be unique per app<br><br>Example:<pre>nlbs = {<br>  nlb01 = {<br>    name                             = "nlb01-inbound"<br>    internal                         = false<br>    eips                             = true<br>    enable_cross_zone_load_balancing = true<br>    apps = {<br>      app01 = {<br>        name          = "inbound-nlb01-app01-ssh"<br>        protocol      = "TCP"<br>        listener_port = "22"<br>        target_port   = "5001"<br>      }<br>      app02 = {<br>        name          = "inbound-nlb01-app02-https"<br>        protocol      = "TCP"<br>        listener_port = "443"<br>        target_port   = "5002"<br>      }<br>    }<br>  }</pre> | `map(any)` | `{}` | no |
| <a name="input_target_instance_ids"></a> [target\_instance\_ids](#input\_target\_instance\_ids) | List of Instance IDs of VM-Series (with interface swap enabled) to be used as targets for all ELBs | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS VPC ID to create ELB resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_test"></a> [test](#output\_test) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Nested Map Input Variable Definitions

For each of the nested map variables, the key of each map will be the terraform state resource identifier within terraform and must be unique, but is not used for resource naming.

### albs

The vpc variable is a map of maps, where each map represents a vpc. Unlike the rest of the nested map vars for this module, the vpc variable is assumed for only a single VPC definition.

There is brownfield support for existing vpc, for this only required to specify `name` and `existing = true`.

The vpc map has the following inputs available (please see examples folder for additional references):

| Name | Description | Type | Default | Required | Brownfield Required
|------|-------------|:----:|:-----:|:-----:|:-----:|
| name | The Name Tag of the new / existing VPC  | string | - | yes | yes |
| existing | Flag only if referencing an existing VPC  | bool | `"false"` | no | yes |
| cidr_block | The CIDR formatted IP range of the VPC being created | string | - | yes | no |
| secondary_cidr_block | List of additional CIDR ranges to asssoicate with VPC | list(string) | - | no | no |
| instance_tenancy | Tenancy option for instances. `"default"`, `"dedicated"`, or `"host"` | string | `"default"` | no | no |
| enable_dns_support | Enable DNS Support | bool | `"true"` | no | no |
| enable_dns_hostnames | Enable DNS hostnames | bool | `"false"` | no | no |
| internet_gateway | Enable IGW creation for this VPC  | bool | `"false"` | no | no |
| local_tags  | Map of aribrary tags key/value pairs to apply to this resource | map | - | no | no |