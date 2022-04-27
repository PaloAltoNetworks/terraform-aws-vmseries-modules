variable "lb_name" {
  description = "Name of the Load Balancer to be created"
  type        = string
}

variable "region" {
  description = "A region used to deploy ALB resource. Only required when creating a new S3 Bucket to store access logs. It's used to map a region to ALB account ID."
  default     = "null"
  type        = string
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer or not."
  default     = false
  type        = bool
}

variable "idle_timeout" {
  description = "The time in seconds that the connection to the Load Balancer can be idle."
  default     = 60
  type        = number
}

variable "desync_mitigation_mode" {
  description = <<-EOF
  Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync.
  Defaults to AWS default. For possible values and current defaults refer to [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#desync_mitigation_mode).
  EOF
  default     = null
  type        = string
}

variable "elb_account_ids" {
  description = "A map of account IDs used by ELB. Useful for setting up `access logs` for ALB."
  default = {
    "us-east-1"      = "127311923021"
    "us-east-2"      = "033677994240"
    "us-west-1"      = "027434742980"
    "us-west-2"      = "797873946194"
    "af-south-1"     = "098369216593"
    "ca-central-1"   = "985666609251"
    "eu-central-1"   = "054676820928"
    "eu-west-1"      = "156460612806"
    "eu-west-2"      = "652711504416"
    "eu-south-1"     = "635631232127"
    "eu-west-3"      = "009996457667"
    "eu-north-1"     = "897822967062"
    "ap-east-1"      = "754344448648"
    "ap-northeast-1" = "582318560864"
    "ap-northeast-2" = "600734575887"
    "ap-northeast-3" = "383597477331"
    "ap-southeast-1" = "114774131450"
    "ap-southeast-2" = "783225319266"
    "ap-south-1"     = "718504428378"
    "me-south-1"     = "076674570225"
    "sa-east-1"      = "507241528517"
    "us-gov-west-1"  = "048591011584"
    "us-gov-east-1"  = "190560391635"
    "cn-north-1"     = "638102146993"
    "cn-northwest-1" = "037604701340"
  }
  type = map(string)
}

variable "configure_access_logs" {
  description = <<-EOF
  Configure Load Balancer to store access logs in an S3 Bucket.
  
  When used with `access_logs_byob` set to `false` forces a creation of a new bucket.
  If however `access_logs_byob` is set to `true` an existing bucket can be used.

  The name of the newly created or existing bucket is controlled via `access_logs_s3_bucket_name`.
  EOF
  default     = false
  type        = bool
}

variable "access_logs_byob" {
  description = <<-EOF
  Bring Your Own Bucket - in case you would like to re-use an existing S3 Bucket for Load Balancer's access logs.

  NOTICE.
  This code does not set up proper `Bucket Policies` for existing buckets. They have to be already in place.
  EOF
  default     = false
  type        = bool
}

variable "access_logs_s3_bucket_name" {
  description = <<-EOF
  Name of an S3 Bucket that will be used as storage for Load Balancer's access logs.

  When used with `configure_access_logs` it becomes the name of a newly created S3 Bucket.
  When used with `access_logs_byob` it is a name of an existing bucket.
  EOF
  default     = "pantf-alb-access-logs-bucket"
  type        = string
}

variable "access_logs_s3_bucket_prefix" {
  description = "A path to a location inside a bucket under which the access logs will be stored. When omitted defaults to the root folder of a bucket."
  default     = null
  type        = string
}

variable "security_groups" {
  description = "A list of security group IDs to use with a Load Balancer."
  type        = list(string)
}

variable "subnets" {
  description = <<-EOF
  Map of subnets used with a Network Load Balancer. Each map's key is the availability zone name and the value is an object that has an attribute
  `id` identifying AWS subnet.
  
  Examples:

  You can define the values directly:

  ```
  subnets = {
    "us-east-1a" = { id = "snet-123007" }
    "us-east-1b" = { id = "snet-123008" }
  }
  ```

  You can also use output from the `subnet_sets` module:
  
  ```
  subnets        = { for k, v in module.subnet_sets["untrust"].subnets : k => { id = v.id } }
  ```
  
  EOF
  type = map(object({
    id = string
  }))
}

variable "enable_cross_zone_load_balancing" {
  description = <<-EOF
  Enable load balancing between instances in different AZs. Defaults to `true`. 
  Change to `false` only if absolutely necessary. By default, there is only one FW in each AZ. 
  Turning this off means 1:1 correlation between a public IP assigned to an AZ and a FW deployed in that AZ.
  EOF

  default = true
  type    = bool
}

variable "vpc_id" {
  description = "ID of the security VPC for the Load Balancer."
  type        = string
}

variable "balance_rules" {
  description = <<-EOF
  An object that contains the listener, target group, and health check configuration. 
  It consists of maps of applications like follows:

  ```
  balance_rules = {
    "application_name" = {
      protocol            = "communication protocol, since this is an ALB module accepted values are `HTTP` or `HTTPS`"
      port                = "communication port, defaults to protocol's default port"
      target_port         = "the port number on which the target accepts communication, defaults to the communication port value"
      targets             = "a map of targets, where key is the target name (used to create a name for the target attachment), value is the target IP (all supported targets are of type `IP`)"
      round_robin         = "use round robin to select backend servers, defaults to `true`, when set to `false` `least_outstanding_requests` is used instead"


      health_check_protocol            = "this can be either `HTTP` or `HTTPS`, default to communication protocol"
      health_check_port                = "port used by the target group health check, if omitted, `traffic-port` will be used"
      health_check_healthy_threshold   = "number of consecutive health checks before considering target healthy, defaults to 3"
      health_check_unhealthy_threshold = "number of consecutive health checks before considering target unhealthy, defaults to 3"
      health_check_interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"
      health_check_matcher             = "response codes expected during health check, defaults to `200` for HTTP(s)"
      health_check_path                = "destination used by the health check request, defaults to `/`"


      certificate_arn   = "(HTTPS ONLY) this is the arn of a certificate"
      ssl_policy        = "(HTTPS ONLY) name of an ssl policy used by the Load Balancer's listener, defaults to AWS default, for available options see [AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies)"
    }
  }
  ```

  The `application_name` key is valid only for letters, numbers and a dash (`-`) - that's an AWS limitation.

  <hr>
  `protocol` and `port` are used for `listener`, `target group` and `target group attachment`. Partially also for health checks (see below).

  <hr>
  All listeners are always of forward action.

  <hr>
  All target are of type `IP`. This is because this is the only option that allows a direct routing between a Load Balancer and a specific network interface. The Application Load Balancer is meant to be always public, therefore the VMSeries IPs should be from the public facing subnet. An example on how to feed this variable with data:

  ```
  fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
  ```

  For format of `var.vmseries` check the [`vmseries` module](../vmseries/README.md). The key is the VM name. By using those keys, we can loop through all vmseries modules and take the private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above). In other words, the `for` loop returns the following map:

  ```
  {
    vm01 = "1.1.1.1"
    vm02 = "2.2.2.2"
    ...
  }
  ```

  <hr>
  Health checks by default use the same protocol as the target group. But this can be overridden. Due to the fact that this module sets up an Application Load Balancer the only options available are: `HTTP` or `HTTPS`.

  <hr>
  EXAMPLE

  ```
  balance_rules = {
    "HTTPS-APP" = {
      protocol                         = "HTTPS"
      port                             = "444"
      health_check_port                = "80"
      health_check_protocol            = "HTTP"
      health_check_healthy_threshold   = 2
      health_check_unhealthy_threshold = 10
      health_check_interval            = 10
      health_check_matcher             = "200-301"
      health_check_path                = "/login.php"
      target_port                      = 8443
      round_robin                      = false

      certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"
      ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

      targets = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
    }
  }
  ```
  EOF
  # For the moment there is no other possibility to specify a `type` for this kind of variable.
  # Even `map(any)` is to restrictive as it requires that all map elements must have the same type.
  # Actually, in our case they have the same type, but they differ in the amount of inner elements.
  type = any
}

variable "tags" {
  description = "Map of AWS tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}