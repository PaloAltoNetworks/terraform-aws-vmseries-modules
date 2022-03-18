variable "lb_name" {
  description = "Name of the LB to be created"
  type        = string
}

variable "lb_dedicated_ips" {
  description = "If set to `true`, a set of EIPs will be created for each zone/subnet. Otherwise AWS will handle IP management. Defaults to `false`."
  type        = bool
  default     = false
}

variable "internal_lb" {
  description = "Determines if this will be a public facing LB (default) or an internal one."
  type        = bool
  default     = false
}


variable "subnet_set_subnets" {
  description = <<-EOF
  A map of subnet objects as returned by the `subnet_set` module for a particular subnet set. 
  An example how to feed this variable with data (assuming usage of this modules as in examples and a subnet set named *untrust*):

  ```hcl
  subnet_set_subnets   = module.subnet_set["untrust"].subnets
  ```

  This map will be indexed by the subnet name and value will contain subnet's arguments as returned by terraform. This includes the subnet's ID.
  EOF
  type        = map(any)
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable load balancing between instances in different AZs. Defaults to `true`. Change to `false` only if you know what you're doing. By default there is only one FW in each AZ. Turning this off means 1:1 correlation between a public IP assigned to an AZ and a FW deployed in that AZ."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the security VPC the LB should be created in."
  type        = string
}

variable "balance_rules" {
  description = <<-EOF
  A object that contains the actual listener, target group and healthcheck configuration. 
  It consist of maps of applications like follows:

  ```hcl
  balance_rules = {
    "application_name" = {
      protocol            = "communication protocol, since this is a NLB module accepted values are TCP or TLS"
      port                = "communication port"
      target_type         = "type of the target that will be attached to a target group, no defaults here, has to be provided explicitly (regardless the defaults terraform could accept)"
      target_port         = "for target types supporting port values, the port number on which the target accepts communication, defaults to the communication port value"
      target              = "a map of targets, where key is the target name (used to create a name for the target attachment), value is the target ID (IP, resource ID, etc - the actual value depends on the target type)"

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
  If you add FWs as targets, make sure you use `target_type = "ip"` and you provide the correct FW IPs in `target` map. IPs should be from the subnet set that the LB was created in. An example on how to feed this variable with data:

  ```hcl
  fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
  ```

  For format of `var.vmseries` check the (`vmseries` module)[../vmseries/README.md]. Basically the key there is the VM name. By using that keys we can loop through all vmseries modules and take private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above). In other words, the `for` loop returns the following map:

  ```hcl
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

  ```hcl
  balance_rules = {
    "HTTPS-APP" = {
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
  ```
  EOF
}

variable "tags" {
  description = "Map of AWS tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}