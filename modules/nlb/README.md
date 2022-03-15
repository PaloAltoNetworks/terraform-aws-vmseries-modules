# Palo Alto Networks Network Load Balancer Module for AWS

A Terraform module for deploying a Network Load Balancer in AWS cloud.

## Usage

<!-- For example usage, please refer to the [Examples](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/examples) directory. -->
TBD

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_balance_rules"></a> [balance\_rules](#input\_balance\_rules) | A object that contains the actual listener, target group and healthcheck configuration. <br>It consist of maps of applications like follows (for NLB - layer 4):<pre>hcl<br>balance_rules = {<br>  "application_name" = {<br>    protocol            = "communication protocol, for NLB prefered is "TCP"<br>    port                = "communication port"<br>    health_check_port   = "port used by the target group healthcheck"<br>    threshold           = "number of consecutive health checks before considering target healthy or unhealthy, defaults to 3"<br>    interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"<br>  }<br>}</pre>`protocol` and `port` are used for `listener`, `target group` and `target group attachment`. Partially also for health checks (see below). By default all target group have all available FW attached (from all AZs).<br><br>All listeners are always of forward action.<br><br>All target groups are always set to `ip`. This way we make sure that the traffic is routed to the correct interface.<br><br>Healthchecks are by default of type TCP. Reason for that is the fact, that HTTP requests might flow through the FW to the actual application. So instead of checking the status of the FW we might check the status of the application.<br><br>You have an option to specify a health check port. This way you can set up a Management Profile with an Administrative Management Service limited only to NLBs private IPs and use a port for that service as the health check port. This way you make sure you separate the actual health check from the application rule's port.<br><br>EXAMPLE<pre>hcl<br>balance_rules = {<br>  "HTTPS_application" = {<br>    protocol          = "TCP"<br>    port              = "443"<br>    health_check_port = "22"<br>    threshold         = 2<br>    interval          = 10<br>  }<br>  "HTTP_application" = {<br>    protocol            = "TCP"<br>    port                = "80"<br>    threshold           = 2<br>    interval            = 10<br>  }<br>}</pre> | `any` | n/a | yes |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable load balancing between instances in different AZs. Defaults to `true`. Change to `false` only if you know what you're doing. By default there is only one FW in each AZ. Turning this off means 1:1 correlcation between a public IP assigned to an AZ and a FW deployed in that AZ. | `bool` | `true` | no |
| <a name="input_fw_instance_ips"></a> [fw\_instance\_ips](#input\_fw\_instance\_ips) | A map of FWs private IPs. IPs should be from the subnet set that the LB was created in.<br>An example on how to feed this variable with data:<pre>hcl<br>fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }</pre>For format of `var.vmseries` check the `vmseries` module. Basically the key there is the VM name. By using that keys we can loop through all vmseries modules and take private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above). | `any` | n/a | yes |
| <a name="input_internal_lb"></a> [internal\_lb](#input\_internal\_lb) | Determines if this will be a public facing LB (default) or an internal one. | `bool` | `false` | no |
| <a name="input_lb_dedicated_ips"></a> [lb\_dedicated\_ips](#input\_lb\_dedicated\_ips) | If set to `true`, a set of EIPs will be created for each zone/subnet. Otherwise AWS will handle IP management. Defaults to `false`. | `bool` | `false` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | Name of the LB to be created | `string` | n/a | yes |
| <a name="input_subnet_set_subnets"></a> [subnet\_set\_subnets](#input\_subnet\_set\_subnets) | A map of subnet objects as returned by the `subnet_set` module for a particular subnet set. <br>An example how to feed this variable with data (assuming usage of this modules as in examples and a subnet set named *untrust*):<pre>hcl<br>subnet_set_subnets   = module.subnet_set["untrust"].subnets</pre>This map will be indexed by the subnet name and value will contain subnet's arguments as returned by terraform. This includes the subnet's ID. | `any` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the security VPC the LB should be created in. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_fqdn"></a> [lb\_fqdn](#output\_lb\_fqdn) | A FQDN for the Network Load Balancer. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->