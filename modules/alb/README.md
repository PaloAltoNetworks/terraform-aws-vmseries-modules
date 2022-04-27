# Palo Alto Networks Application Load Balancer Module for AWS

A Terraform module for deploying an Application Load Balancer in AWS cloud. This is always a public Load Balancer with Target Groups of `IP` type. It is intended to be placed just in front of Next Generation Firewalls.

## Usage

Example usage:

* The code below is designed to be used with [`vmseries`](../vmseries/README.md), [`vpc`](../vpc/README.md) and [`subnet_set`](../subnet_set/README.md) modules. Check these modules for information on outputs used in this code.
* Firewalls' public facing interfaces are placed in a subnet set called *untrust*.
* There are two rules shown below:
  * `defaults` rule shows a minimum setup that uses only default values
  * `https-custom` rule shows all possible properties and example values.

```
module "public_nlb" {
  source = "../../modules/nlb"

  lb_name = "public-alb"
  region  = var.region

  subnets                    = { for k, v in module.security_subnet_sets["untrust"].subnets : k => { id = v.id } }
  desync_mitigation_mode     = "monitor"
  vpc_id                     = module.security_vpc.id
  configure_access_logs      = true
  access_logs_s3_bucket_name = "alb-logs-bucket"
  security_groups            = [module.security_vpc.security_group_ids["load_balancer"]]

  balance_rules = {
    "defaults" = {
      protocol = "HTTP"
      targets  = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
    }
    "https-custom" = {
      protocol                         = "HTTPS"
      port                             = "444"
      target_port                      = 8443
      round_robin                      = false

      health_check_port                = "80"
      health_check_healthy_threshold   = 2
      health_check_unhealthy_threshold = 10
      health_check_interval            = 10
      health_check_protocol            = "HTTP"
      health_check_matcher             = "200-301"
      health_check_path                = "/login.php"

      certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"
      ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

      targets = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.74 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.example_bucket_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_byob"></a> [access\_logs\_byob](#input\_access\_logs\_byob) | Bring Your Own Bucket - in case you would like to re-use an existing S3 Bucket for Load Balancer's access logs.<br><br>NOTICE.<br>This code does not set up proper `Bucket Policies` for existing buckets. They have to be already in place. | `bool` | `false` | no |
| <a name="input_access_logs_s3_bucket_name"></a> [access\_logs\_s3\_bucket\_name](#input\_access\_logs\_s3\_bucket\_name) | Name of an S3 Bucket that will be used as storage for Load Balancer's access logs.<br><br>When used with `configure_access_logs` it becomes the name of a newly created S3 Bucket.<br>When used with `access_logs_byob` it is a name of an existing bucket. | `string` | `"pantf-alb-access-logs-bucket"` | no |
| <a name="input_access_logs_s3_bucket_prefix"></a> [access\_logs\_s3\_bucket\_prefix](#input\_access\_logs\_s3\_bucket\_prefix) | A path to a location inside a bucket under which the access logs will be stored. When omitted defaults to the root folder of a bucket. | `string` | `null` | no |
| <a name="input_balance_rules"></a> [balance\_rules](#input\_balance\_rules) | An object that contains the listener, target group, and health check configuration. <br>It consists of maps of applications like follows:<pre>balance_rules = {<br>  "application_name" = {<br>    protocol            = "communication protocol, since this is an ALB module accepted values are `HTTP` or `HTTPS`"<br>    port                = "communication port, defaults to protocol's default port"<br>    target_port         = "the port number on which the target accepts communication, defaults to the communication port value"<br>    targets             = "a map of targets, where key is the target name (used to create a name for the target attachment), value is the target IP (all supported targets are of type `IP`)"<br>    round_robin         = "use round robin to select backend servers, defaults to `true`, when set to `false` `least_outstanding_requests` is used instead"<br><br><br>    health_check_protocol            = "this can be either `HTTP` or `HTTPS`, default to communication protocol"<br>    health_check_port                = "port used by the target group health check, if omitted, `traffic-port` will be used"<br>    health_check_healthy_threshold   = "number of consecutive health checks before considering target healthy, defaults to 3"<br>    health_check_unhealthy_threshold = "number of consecutive health checks before considering target unhealthy, defaults to 3"<br>    health_check_interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"<br>    health_check_matcher             = "response codes expected during health check, defaults to `200` for HTTP(s)"<br>    health_check_path                = "destination used by the health check request, defaults to `/`"<br><br><br>    certificate_arn   = "(HTTPS ONLY) this is the arn of a certificate"<br>    ssl_policy        = "(HTTPS ONLY) name of an ssl policy used by the Load Balancer's listener, defaults to AWS default, for available options see [AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies)"<br>  }<br>}</pre>The `application_name` key is valid only for letters, numbers and a dash (`-`) - that's an AWS limitation.<br><br><hr><br>`protocol` and `port` are used for `listener`, `target group` and `target group attachment`. Partially also for health checks (see below).<br><br><hr><br>All listeners are always of forward action.<br><br><hr><br>All target are of type `IP`. This is because this is the only option that allows a direct routing between a Load Balancer and a specific network interface. The Application Load Balancer is meant to be always public, therefore the VMSeries IPs should be from the public facing subnet. An example on how to feed this variable with data:<pre>fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }</pre>For format of `var.vmseries` check the [`vmseries` module](../vmseries/README.md). The key is the VM name. By using those keys, we can loop through all vmseries modules and take the private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above). In other words, the `for` loop returns the following map:<pre>{<br>  vm01 = "1.1.1.1"<br>  vm02 = "2.2.2.2"<br>  ...<br>}</pre><hr><br>Health checks by default use the same protocol as the target group. But this can be overridden. Due to the fact that this module sets up an Application Load Balancer the only options available are: `HTTP` or `HTTPS`.<br><br><hr><br>EXAMPLE<pre>balance_rules = {<br>  "HTTPS-APP" = {<br>    protocol                         = "HTTPS"<br>    port                             = "444"<br>    health_check_port                = "80"<br>    health_check_protocol            = "HTTP"<br>    health_check_healthy_threshold   = 2<br>    health_check_unhealthy_threshold = 10<br>    health_check_interval            = 10<br>    health_check_matcher             = "200-301"<br>    health_check_path                = "/login.php"<br>    target_port                      = 8443<br>    round_robin                      = false<br><br>    certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"<br>    ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"<br><br>    targets = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }<br>  }<br>}</pre> | `any` | n/a | yes |
| <a name="input_configure_access_logs"></a> [configure\_access\_logs](#input\_configure\_access\_logs) | Configure Load Balancer to store access logs in an S3 Bucket.<br><br>When used with `access_logs_byob` set to `false` forces a creation of a new bucket.<br>If however `access_logs_byob` is set to `true` an existing bucket can be used.<br><br>The name of the newly created or existing bucket is controlled via `access_logs_s3_bucket_name`. | `bool` | `false` | no |
| <a name="input_desync_mitigation_mode"></a> [desync\_mitigation\_mode](#input\_desync\_mitigation\_mode) | Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync.<br>Defaults to AWS default. For possible values and current defaults refer to [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#desync_mitigation_mode). | `string` | `null` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer or not. | `bool` | `false` | no |
| <a name="input_elb_account_ids"></a> [elb\_account\_ids](#input\_elb\_account\_ids) | A map of account IDs used by ELB. Useful for setting up `access logs` for ALB. | `map(string)` | <pre>{<br>  "af-south-1": "098369216593",<br>  "ap-east-1": "754344448648",<br>  "ap-northeast-1": "582318560864",<br>  "ap-northeast-2": "600734575887",<br>  "ap-northeast-3": "383597477331",<br>  "ap-south-1": "718504428378",<br>  "ap-southeast-1": "114774131450",<br>  "ap-southeast-2": "783225319266",<br>  "ca-central-1": "985666609251",<br>  "cn-north-1": "638102146993",<br>  "cn-northwest-1": "037604701340",<br>  "eu-central-1": "054676820928",<br>  "eu-north-1": "897822967062",<br>  "eu-south-1": "635631232127",<br>  "eu-west-1": "156460612806",<br>  "eu-west-2": "652711504416",<br>  "eu-west-3": "009996457667",<br>  "me-south-1": "076674570225",<br>  "sa-east-1": "507241528517",<br>  "us-east-1": "127311923021",<br>  "us-east-2": "033677994240",<br>  "us-gov-east-1": "190560391635",<br>  "us-gov-west-1": "048591011584",<br>  "us-west-1": "027434742980",<br>  "us-west-2": "797873946194"<br>}</pre> | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable load balancing between instances in different AZs. Defaults to `true`. <br>Change to `false` only if absolutely necessary. By default, there is only one FW in each AZ. <br>Turning this off means 1:1 correlation between a public IP assigned to an AZ and a FW deployed in that AZ. | `bool` | `true` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The time in seconds that the connection to the Load Balancer can be idle. | `number` | `60` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | Name of the Load Balancer to be created | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | A region used to deploy ALB resource. Only required when creating a new S3 Bucket to store access logs. It's used to map a region to ALB account ID. | `string` | `"null"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | A list of security group IDs to use with a Load Balancer. | `list(string)` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnets used with a Network Load Balancer. Each map's key is the availability zone name and the value is an object that has an attribute<br>`id` identifying AWS subnet.<br><br>Examples:<br><br>You can define the values directly:<pre>subnets = {<br>  "us-east-1a" = { id = "snet-123007" }<br>  "us-east-1b" = { id = "snet-123008" }<br>}</pre>You can also use output from the `subnet_sets` module:<pre>subnets        = { for k, v in module.subnet_sets["untrust"].subnets : k => { id = v.id } }</pre> | <pre>map(object({<br>    id = string<br>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of AWS tags to apply to all the created resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the security VPC for the Load Balancer. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_fqdn"></a> [lb\_fqdn](#output\_lb\_fqdn) | A FQDN for the Load Balancer. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->