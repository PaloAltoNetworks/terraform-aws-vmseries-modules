variable "name" {
  description = "Name of the Load Balancer to be created, must be less or equal to 32 char."
  type        = string
}

variable "create_dedicated_eips" {
  description = "If set to `true`, a set of EIPs will be created for each zone/subnet. Otherwise AWS will handle IP management."
  default     = false
  type        = bool
}

variable "internal_lb" {
  description = "Determines if this Load Balancer will be a public (default) or an internal one."
  default     = false
  type        = bool
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
  description = "ID of the security VPC the Load Balancer should be created in."
  type        = string
}

variable "balance_rules" {
  description = <<-EOF
  An object that contains the listener, target group, and health check configuration. 
  It consist of maps of applications like follows:

  ```
  balance_rules = {
    "application_name" = {
      protocol            = "communication protocol, since this is a NLB module accepted values are TCP or TLS"
      port                = "communication port"
      target_type         = "type of the target that will be attached to a target group, no defaults here, has to be provided explicitly (regardless the defaults terraform could accept)"
      target_port         = "for target types supporting port values, the port number on which the target accepts communication, defaults to the communication port value"
      targets             = "a map of targets, where key is the target name (used to create a name for the target attachment), value is the target ID (IP, resource ID, etc - the actual value depends on the target type)"

      health_check_port   = "port used by the target group healthcheck, if ommited, `traffic-port` will be used"
      threshold           = "number of consecutive health checks before considering target healthy or unhealthy, defaults to 3"
      interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"

      certificate_arn     = "(TLS ONLY) this is the arn of a certificate"
      alpn_policy         = "(TLS ONLY) ALPN policy name, for possible values check (terraform documentation)[https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#alpn_policy], defaults to `None`"
    }
  }
  ```

  The `application_name` key is valid only for letters, numbers and a dash (`-`) - that's an AWS limitation.

  <hr>
  `protocol` and `port` are used for `listener`, `target group` and `target group attachment`. Partially also for health checks (see below).

  <hr>
  All listeners are always of forward action.

  <hr>
  If you add FWs as targets, make sure you use `target_type = "ip"` and you provide the correct FW IPs in `target` map. IPs should be from the subnet set that the Load Balancer was created in. An example on how to feed this variable with data:

  ```
  fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
  ```

  For format of `var.vmseries` check the (`vmseries` module)[../vmseries/README.md]. The key is the VM name. By using those keys, we can loop through all vmseries modules and take the private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above). In other words, the `for` loop returns the following map:

  ```
  {
    vm01 = "1.1.1.1"
    vm02 = "2.2.2.2"
    ...
  }
  ```

  <hr>
  Healthchecks are by default of type TCP. Reason for that is the fact, that HTTP requests might flow through the FW to the actual application. So instead of checking the status of the FW we might check the status of the application.

  You have an option to specify a health check port. This way you can set up a Management Profile with an Administrative Management Service limited only to NLBs private IPs and use a port for that service as the health check port. This way you make sure you separate the actual health check from the application rule's port.

  <hr>
  EXAMPLE

  ```
  balance_rules = {
    "HTTPS-APP" = {
      protocol          = "TCP"
      port              = "443"
      health_check_port = "80"
      threshold         = 2
      interval          = 10
      target_port       = 8443
      target_type       = "ip"
      targets           = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
      stickiness        = true
    }
  }
  ```
  EOF
  # For the moment there is no other possibility to specify a `type` for this kind of variable.
  # Even `map(any)` is to restrictive as it requires that all map elements must have the same type.
  # Actually, in our case they have the same type, but they differ in the mount of inner elements.
  type = any
}

variable "tags" {
  description = "Map of AWS tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}