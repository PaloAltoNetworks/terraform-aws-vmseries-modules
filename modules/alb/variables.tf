variable "lb_name" {
  description = "Name of the Load Balancer to be created."
  type        = string
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the Load Balancer or not."
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
  Determines how the Load Balancer handles requests that might pose a security risk to an application due to HTTP desync.
  Defaults to AWS default. For possible values and current defaults refer to [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#desync_mitigation_mode).
  EOF
  default     = null
  type        = string
}

variable "configure_access_logs" {
  description = <<-EOF
  Configure Load Balancer to store access logs in an S3 Bucket.
  
  When used with `access_logs_byob` set to `false` forces creation of a new bucket.
  If, however, `access_logs_byob` is set to `true` an existing bucket can be used.

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
  description = "A path to a location inside a bucket under which access logs will be stored. When omitted defaults to the root folder of a bucket."
  default     = null
  type        = string
}

variable "security_groups" {
  description = <<-EOF
  A list of security group IDs to use with a Load Balancer.

  If security groups are created with a [VPC module](../vpc/README.md) you can use output from that module like this:
  ```
  security_groups              = [module.vpc.security_group_ids["load_balancer_security_group"]]
  ```
  For more information on meaning of the `load_balancer_security_group` key refer to the [VPC module documentation](../vpc/README.md).
  EOF
  type        = list(string)
}

variable "subnets" {
  description = <<-EOF
  Map of subnets used with a Load Balancer. Each key is the availability zone name and the value is an object that has an attribute
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

variable "rules" {
  description = <<-EOF
  An object that contains the listener, listener_rules, target group, and health check configuration. 
  It consists of maps of applications with their properties, like in the following example:

  ```
  rules = {
    "application_name" = {
      protocol            = "communication protocol, since this is an ALB module accepted values are `HTTP` or `HTTPS`"
      port                = "communication port, defaults to protocol's default port"

      certificate_arn   = "(HTTPS ONLY) this is the arn of an existing certificate, this module will not create one for you"
      ssl_policy        = "(HTTPS ONLY) name of an ssl policy used by the Load Balancer's listener, defaults to AWS default, for available options see [AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies)"

      health_check_protocol            = "this can be either `HTTP` or `HTTPS`, defaults to communication protocol"
      health_check_port                = "port used by the target group health check, if omitted, `traffic-port` will be used (which will be the same as communication port)"
      health_check_healthy_threshold   = "number of consecutive health checks before considering target healthy, defaults to 3"
      health_check_unhealthy_threshold = "number of consecutive health checks before considering target unhealthy, defaults to 3"
      health_check_interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"
      health_check_timeout             = "health check probe timeout, defaults to AWS default value"
      health_check_matcher             = "response codes expected during health check, defaults to `200`"
      health_check_path                = "destination used by the health check request, defaults to `/`"

      listener_rules    = "a map of rules for a listener created for this application, see `listener_rules` block below for more information
    }
  }
  ```

  The `application_name` key is valid only for letters, numbers and a dash (`-`) - that's an AWS limitation.

  <hr>
  There is always one listener created per application. The listener has always a default action that responds with `503`. This should be treated as a `catch-all` rule. For the listener to send traffic to backends a listener rule has to be created. This is controlled via the `listener_rules` map. 

  A key in this map is the priority of the listener rule. Priority can be between `1` and `50000` (AWS specifics). All properties under a particular key refer to either rule's condition(s) or the target group that should receive traffic if a rule is met. 

  Rule conditions - at least one but not more than five of: `host_headers`, `http_headers`, `http_request_method`, `path_pattern`, `query_strings` or `source_ip` has to be set. For more information on what conditions can be set for each type refer to [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule#condition-blocks).

  Target group - keep in mind that all target group attachments are always pointing to VMSeries' public interfaces. The difference between target groups for each rule is the protocol and/or port to which the traffic is being directed. And these are the only properties you can configure.

  The `listener_rules` map presents as follows:

  ```
  listener_rules = {
    "rule_priority" = {      # string representation of a rule's priority (number from 1 - 50000)
      target_port           = "port on which the target is listening for requests"
      target_protocol       = "target protocol, can be `HTTP` or `HTTPS`"
      protocol_version      = "one of `HTTP1`, `HTTP/2` or `GRPC`, defaults to `HTTP1`"
      host_headers          = "a list of possible host headers, case insensitive, wildcards (`*`,`?`) are supported"
      http_headers          = "a map of key-value pairs, where key is a name of an HTTP header and value is a list of possible values, same rules apply like for `host_headers`"
      http_request_method   = "a list of possible HTTP request methods, case sensitive (upper case only), strict matching (no wildcards)"
      path_pattern          = "a list of path patterns (w/o query strings), case sensitive, wildcards supported"
      query_strings         = "a map of key-value pairs, key is a query string key pattern and value is a query string value pattern, case insensitive, wildcards supported, it is possible to match only a value pattern (the key value should be prefixed with `nokey_`)"
      source_ip             = "a map of source IP CDIR notation to match"
    }
  }
  ```

  <hr>
  EXAMPLE

  ```
  listener_rules = {
    "1" = {
      target_port     = 8080
      target_protocol = "HTTP"
      host_headers    = ["public-alb-1050443040.eu-west-1.elb.amazonaws.com"]
      http_headers = {
        "X-Forwarded-For" = ["192.168.1.*"]
      }
      http_request_method = ["GET"]
    }
    "99" = {
      host_headers    = ["www.else.org"]
      target_port     = 8081
      target_protocol = "HTTP"
      path_pattern    = ["/", "/login.php"]
      query_strings = {
        "lang"    = "us"
        "nokey_1" = "test"
      }
      source_ip = ["10.0.0.0/8"]
    }
  }
  ```
  EOF
  # For the moment there is no other possibility to specify a `type` for this kind of variable.
  # Even `map(any)` is to restrictive as it requires that all map elements must have the same type.
  # Actually, in our case they have the same type, but they differ in the amount of inner elements.
  type = any
}

variable "targets" {
  description = <<-EOF
  A list of backends accepting traffic. For Application Load Balancer all targets are of type `IP`. This is because this is the only option that allows a direct routing between a Load Balancer and a specific VMSeries' network interface. The Application Load Balancer is meant to be always public, therefore the VMSeries IPs should be from the public facing subnet. An example on how to feed this variable with data:

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
  EOF
  type        = map(string)
}

variable "tags" {
  description = "Map of AWS tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}