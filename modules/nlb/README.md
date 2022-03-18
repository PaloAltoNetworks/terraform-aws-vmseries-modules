# Palo Alto Networks Network Load Balancer Module for AWS

A Terraform module for deploying a Network Load Balancer in AWS cloud. This can be used both as a public facing LB (to balance incoming traffic to NGFWs) or as an internal LB (to balance traffic from FW to the actual application.)

## Usage

Example usage as a public LB:

* The code below is designed to be used with [`vmseries`](../vmseries/README.md), [`vpc`](../vpc/README.md) and [`subnet_set`](../subnet_set/README.md) modules. Check these modules for information on outputs used in this code.
* Friewalls' public facing interfaces are places in a subnet set called *untrust*.
* health check port is set to `22` because it uses the SSH Management Service (limited on the FW to Load Balancer's private IP only)
* in the `HTTPS-traffic` rule one can see a port shift, from `443` on the LB to `8443` in the firewall.

```hcl
module "public_nlb" {
  source = "../../modules/nlb"

  lb_name            = "public-nlb"
  subnet_set_subnets = module.security_subnet_sets["untrust"].subnets
  lb_dedicated_ips   = true
  vpc_id             = module.security_vpc.id
  balance_rules = {
    "HTTP-traffic" = {
      protocol          = "TCP"
      port              = "80"
      health_check_port = "22"
      threshold         = 2
      interval          = 10
      target_type       = "ip"
      targets           = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
      stickiness        = true
    }
    "HTTPS-traffic" = {
      protocol          = "TCP"
      port              = "443"
      health_check_port = "22"
      threshold         = 2
      interval          = 10
      target_port       = 8443
      target_type       = "ip"
      targets           = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
      stickiness        = true
    }
  }

  tags = var.global_tags
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.10 |

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
| [aws_network_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_balance_rules"></a> [balance\_rules](#input\_balance\_rules) | A object that contains the actual listener, target group and healthcheck configuration. <br>It consist of maps of applications like follows:<pre>hcl<br>balance_rules = {<br>  "application_name" = {<br>    protocol            = "communication protocol, since this is a NLB module accepted values are TCP or TLS"<br>    port                = "communication port"<br>    target_type         = "type of the target that will be attached to a target group, no defaults here, has to be provided explicitly (regardless the defaults terraform could accept)"<br>    target_port         = "for target types supporting port values, the port number on which the target accepts communication, defaults to the communication port value"<br>    target              = "a map of targets, where key is the target name (used to create a name for the target attachment), value is the target ID (IP, resource ID, etc - the actual value depends on the target type)"<br><br>    health_check_port   = "port used by the target group healthcheck, if ommited, `traffic-port` will be used"<br>    threshold           = "number of consecutive health checks before considering target healthy or unhealthy, defaults to 3"<br>    interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"<br><br>    certificate_arn     = "(TLS ONLY) this is the arn of a certificate"<br>    alpn_policy         = "(TLS ONLY) ALPN policy name, for possible values check (terraform documentation)[https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#alpn_policy], defaults to `None`"<br>  }<br>}</pre>The `application_name` key is valid only for letters, numbers and a dash (`-`) - that's an AWS limitation.<br><br><hr><br>`protocol` and `port` are used for `listener`, `target group` and `target group attachment`. Partially also for health checks (see below).<br><br><hr><br>All listeners are always of forward action.<br><br><hr><br>If you add FWs as targets, make sure you use `target_type = "ip"` and you provide the correct FW IPs in `target` map. IPs should be from the subnet set that the LB was created in. An example on how to feed this variable with data:<pre>hcl<br>fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }</pre>For format of `var.vmseries` check the (`vmseries` module)[../vmseries/README.md]. Basically the key there is the VM name. By using that keys we can loop through all vmseries modules and take private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above). In other words, the `for` loop returns the following map:<pre>hcl<br>{<br>  vm01 = "1.1.1.1"<br>  vm02 = "2.2.2.2"<br>  ...<br>}</pre><hr><br>Healthchecks are by default of type TCP. Reason for that is the fact, that HTTP requests might flow through the FW to the actual application. So instead of checking the status of the FW we might check the status of the application.<br><br>You have an option to specify a health check port. This way you can set up a Management Profile with an Administrative Management Service limited only to NLBs private IPs and use a port for that service as the health check port. This way you make sure you separate the actual health check from the application rule's port.<br><br><hr><br>EXAMPLE<pre>hcl<br>balance_rules = {<br>  "HTTPS-APP" = {<br>    protocol          = "TCP"<br>    port              = "443"<br>    health_check_port = "22"<br>    threshold         = 2<br>    interval          = 10<br>    target_port       = 8443<br>    target_type       = "ip"<br>    targets           = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }<br>    stickiness        = true<br>  }<br>}</pre> | `any` | n/a | yes |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable load balancing between instances in different AZs. Defaults to `true`. Change to `false` only if you know what you're doing. By default there is only one FW in each AZ. Turning this off means 1:1 correlation between a public IP assigned to an AZ and a FW deployed in that AZ. | `bool` | `true` | no |
| <a name="input_internal_lb"></a> [internal\_lb](#input\_internal\_lb) | Determines if this will be a public facing LB (default) or an internal one. | `bool` | `false` | no |
| <a name="input_lb_dedicated_ips"></a> [lb\_dedicated\_ips](#input\_lb\_dedicated\_ips) | If set to `true`, a set of EIPs will be created for each zone/subnet. Otherwise AWS will handle IP management. Defaults to `false`. | `bool` | `false` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | Name of the LB to be created | `string` | n/a | yes |
| <a name="input_subnet_set_subnets"></a> [subnet\_set\_subnets](#input\_subnet\_set\_subnets) | A map of subnet objects as returned by the `subnet_set` module for a particular subnet set. <br>An example how to feed this variable with data (assuming usage of this modules as in examples and a subnet set named *untrust*):<pre>hcl<br>subnet_set_subnets   = module.subnet_set["untrust"].subnets</pre>This map will be indexed by the subnet name and value will contain subnet's arguments as returned by terraform. This includes the subnet's ID. | `map(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of AWS tags to apply to all the created resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the security VPC the LB should be created in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_fqdn"></a> [lb\_fqdn](#output\_lb\_fqdn) | A FQDN for the Network Load Balancer. |
| <a name="output_lb_private_ips"></a> [lb\_private\_ips](#output\_lb\_private\_ips) | A map of private IPs with keys set to AZ names |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->