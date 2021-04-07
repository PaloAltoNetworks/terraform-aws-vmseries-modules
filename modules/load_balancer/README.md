# Terraform AWS ELB PAN NAT

Create resources on AWS and PANOS for use for ingress "load balancer sandwich" style deployments.

Can create either public Application Load Balancers and / or Network Load balancers for use in inbound applications. Each inbound application is defined separately and will be send to the PANOS vm-series firewalls on a unique port.

Optionall this module can create NAT and security policies in Panorama correlated with each inbound application defined to translate each unique port back to the appropriate back-end. If you are not using this functionality, simply do not define any values for these variables.

Load balancers and Applications are defined in map variables. Check `variables.tf` for description and examples of each value.

## AWS
Assumes existing VPC with vm-series FW instances deployed using interface swap mechanism so that default eth0 interfaces are in public subnets.


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
| <a name="input_alb_apps"></a> [alb\_apps](#input\_alb\_apps) | "Map of Inbound Applications and associated parameters to create AWS NLB and listeners and PANOS NAT policies. All fields required.<br>        key            = Name of inbound application. Used for naming and referencing of multiple AWS and PANOS resources for each application<br>        lb\_name        = Name of nlb to reference to create listener and associate new target group for each application<br>        rule\_type      = 'path' or 'host'. Must match with data type used for 'rule\_pattern'<br>        rule\_pattern   = Either the URI path pattern or host-header based pattern to match for each application for rules on ALB<br>        front\_end\_port = TCP port to use for NLB listener and PANOS NAT Policy. Should be unique per application<br>        back\_end\_type  = 'fqdn' or 'ip-netmask'. Must match with data type used for 'back-end\_host'<br>        back\_end\_host  = Hostname or IP address of back-end resource that traffic will be NAT'd to for each application. Do not include mask on IP address<br>        back\_end\_port  = TCP port for the destination NAT translation to the back-end. Can keep on same port as front-end or standardize to 443, etc | `map` | <pre>{<br>  "alb_app001": {<br>    "back_end_host": "10.141.0.101",<br>    "back_end_port": "2501",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2501",<br>    "lb_name": "inbound-alb01",<br>    "rule_pattern": "/customer1/*",<br>    "rule_type": "path"<br>  },<br>  "alb_app002": {<br>    "back_end_host": "10.141.0.102",<br>    "back_end_port": "2502",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2502",<br>    "lb_name": "inbound-alb01",<br>    "rule_pattern": "/customer2/*",<br>    "rule_type": "path"<br>  },<br>  "alb_app003": {<br>    "back_end_host": "10.141.0.103",<br>    "back_end_port": "2503",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2503",<br>    "lb_name": "inbound-alb01",<br>    "rule_pattern": "customer1.domain.com",<br>    "rule_type": "host"<br>  },<br>  "alb_app004": {<br>    "back_end_host": "10.141.0.104",<br>    "back_end_port": "2504",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2504",<br>    "lb_name": "inbound-alb01",<br>    "rule_pattern": "customer2.domain.com",<br>    "rule_type": "host"<br>  },<br>  "alb_app005": {<br>    "back_end_host": "10.141.0.105",<br>    "back_end_port": "2505",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2505",<br>    "lb_name": "inbound-alb01",<br>    "rule_pattern": "customer3.domain.com",<br>    "rule_type": "host"<br>  },<br>  "alb_app051": {<br>    "back_end_host": "app005.internal-lb.ec2-aws",<br>    "back_end_port": "2551",<br>    "back_end_type": "fqdn",<br>    "front_end_port": "2551",<br>    "lb_name": "inbound-alb02",<br>    "rule_pattern": "customer51.domain.com",<br>    "rule_type": "host"<br>  }<br>}</pre> | no |
| <a name="input_albs"></a> [albs](#input\_albs) | "Map of AWS Application Load balancers to create. Can have 100 rules per ALB. All fields required.<br>        key              = Name of ALB. Used for naming and referencing of multiple AWS and PANOS resources<br>        lb\_internal      = Must be false for creating public ELB<br>        lb\_type          = Must be 'application' for creating ALB<br>        certificate\_arn  = ARN of existing ACM or IAM certificate to use for HTTPS termination<br>        subnets          = List of subnet IDs to associate with ALB<br>        security\_groups  = List of security group IDs to associate with ALB | `map` | <pre>{<br>  "inbound-alb01": {<br>    "certificate_arn": "arn:aws:acm:ca-central-1:123456:certificate/12345-1234-12345-12345",<br>    "lb_internal": false,<br>    "lb_type": "application",<br>    "security_groups": [<br>      "sg-1234567"<br>    ],<br>    "subnets": [<br>      "subnet-123456789",<br>      "subnet-123456789"<br>    ]<br>  },<br>  "inbound-alb02": {<br>    "certificate_arn": "arn:aws:acm:ca-central-1:123456:certificate/12345-1234-12345-12345",<br>    "lb_internal": false,<br>    "lb_type": "application",<br>    "security_groups": [<br>      "sg-1234567"<br>    ],<br>    "subnets": [<br>      "subnet-123456789",<br>      "subnet-123456789"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_elb_subnet_ids"></a> [elb\_subnet\_ids](#input\_elb\_subnet\_ids) | List of Subnet IDs to be used as targets for all ELBs | `list(any)` | `[]` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Map of tags (key / value pairs) to apply to all AWS resources | `map` | <pre>{<br>  "environment": "Prod",<br>  "owner": "Security Ops"<br>}</pre> | no |
| <a name="input_nlb_apps"></a> [nlb\_apps](#input\_nlb\_apps) | Map of Inbound Applications and associated parameters to create AWS ALB rules and PANOS NAT policies. All fields required.<br>        key            = Name of inbound application. Used for naming and referencing of multiple AWS and PANOS resources for each application<br>        lb\_name        = Name of nlb to reference to create listener and associate new target group for each application<br>        protocol       = 'TCP', 'UDP'<br>        front\_end\_port = TCP port to use for NLB listener and PANOS NAT Policy. Should be unique per application<br>        back\_end\_type  = 'fqdn' or 'ip-netmask'. Must match with data type used for 'back-end\_host'<br>        back\_end\_host  = Hostname or IP address of back-end resource that traffic will be NAT'd to for each application. Do not include mask on IP address<br>        back\_end\_port  = TCP port for the destination NAT translation to the back-end. Can keep on same port as front-end or standardize to 443, etc | `map` | <pre>{<br>  "nlb_app001": {<br>    "back_end_host": "10.140.1.101",<br>    "back_end_port": "2401",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2401",<br>    "lb_name": "inbound-nlb01",<br>    "protocol": "TCP"<br>  },<br>  "nlb_app002": {<br>    "back_end_host": "app002.internal-lb.aws",<br>    "back_end_port": "2402",<br>    "back_end_type": "fqdn",<br>    "front_end_port": "2402",<br>    "lb_name": "inbound-nlb01",<br>    "protocol": "TCP"<br>  },<br>  "nlb_app003": {<br>    "back_end_host": "app003.internal-lb.aws",<br>    "back_end_port": "2403",<br>    "back_end_type": "fqdn",<br>    "front_end_port": "2403",<br>    "lb_name": "inbound-nlb01",<br>    "protocol": "UDP"<br>  },<br>  "nlb_app004": {<br>    "back_end_host": "app004.internal-lb.aws",<br>    "back_end_port": "2404",<br>    "back_end_type": "fqdn",<br>    "front_end_port": "2404",<br>    "lb_name": "inbound-nlb01",<br>    "protocol": "UDP"<br>  },<br>  "nlb_app005": {<br>    "back_end_host": "10.140.1.105",<br>    "back_end_port": "2405",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2405",<br>    "lb_name": "inbound-nlb01",<br>    "protocol": "TCP"<br>  },<br>  "nlb_app051": {<br>    "back_end_host": "10.140.50.105",<br>    "back_end_port": "2451",<br>    "back_end_type": "ip-netmask",<br>    "front_end_port": "2451",<br>    "lb_name": "inbound-nlb02",<br>    "protocol": "TCP"<br>  }<br>}</pre> | no |
| <a name="input_nlbs"></a> [nlbs](#input\_nlbs) | Nested Map of AWS Network Load balancers to create and the "apps" (target groups, listeners) associated with each.<pre>- key = Unique reference for each NLB<br>- name             = Name<br>- lb_internal      = Must be false for creating public NLB<br>- enable_cross_zone_load_balancing = Set to true to enable each front-end to send traffic to all targets<br>- lb_type          = Must be 'network' for creating NLB<br>- subnets          = List of subnet IDs to associate with ALB. EIP will be created per subnet and associated to NLB<br><br>nlbs = {<br>  nlb01 = {<br>    name                             = "nlb01-inbound"<br>    internal                         = false<br>    eips                             = true<br>    enable_cross_zone_load_balancing = true<br>    apps = {<br>      app01 = {<br>        name          = "inbound-nlb01-app01-ssh"<br>        protocol      = "TCP"<br>        listener_port = "22"<br>        target_port   = "5001"<br>      }<br>      app02 = {<br>        name          = "inbound-nlb01-app02-https"<br>        protocol      = "TCP"<br>        listener_port = "443"<br>        target_port   = "5002"<br>      }<br>    }<br>  }</pre> | `map` | `{}` | no |
| <a name="input_target_instance_ids"></a> [target\_instance\_ids](#input\_target\_instance\_ids) | List of Instance IDs of PANOS vm-series (with interface swap enabled) to be used as targets for all ELBs | `list(any)` | <pre>[<br>  "i-01234567890",<br>  "i-01234567890"<br>]</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS VPC ID to create ELB resources | `string` | `"vpc-1234567890"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_test"></a> [test](#output\_test) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->