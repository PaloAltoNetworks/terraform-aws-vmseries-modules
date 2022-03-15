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
  description = "Enable load balancing between instances in different AZs. Defaults to `true`. Change to `false` only if you know what you're doing. By default there is only one FW in each AZ. Turning this off means 1:1 correlcation between a public IP assigned to an AZ and a FW deployed in that AZ."
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
  It consist of maps of applications like follows (for NLB - layer 4):

  ```hcl
  balance_rules = {
    "application_name" = {
      protocol            = "communication protocol, for NLB prefered is "TCP"
      port                = "communication port"
      health_check_port   = "port used by the target group healthcheck"
      threshold           = "number of consecutive health checks before considering target healthy or unhealthy, defaults to 3"
      interval            = "time between each health check, between 5 and 300 seconds, defaults to 30s"
    }
  }
  ```

  `protocol` and `port` are used for `listener`, `target group` and `target group attachment`. Partially also for health checks (see below). By default all target group have all available FW attached (from all AZs).

  All listeners are always of forward action.

  All target groups are always set to `ip`. This way we make sure that the traffic is routed to the correct interface.

  Healthchecks are by default of type TCP. Reason for that is the fact, that HTTP requests might flow through the FW to the actual application. So instead of checking the status of the FW we might check the status of the application.

  You have an option to specify a health check port. This way you can set up a Management Profile with an Administrative Management Service limited only to NLBs private IPs and use a port for that service as the health check port. This way you make sure you separate the actual health check from the application rule's port.

  EXAMPLE

  ```hcl
  balance_rules = {
    "HTTPS_application" = {
      protocol          = "TCP"
      port              = "443"
      health_check_port = "22"
      threshold         = 2
      interval          = 10
    }
    "HTTP_application" = {
      protocol            = "TCP"
      port                = "80"
      threshold           = 2
      interval            = 10
    }
  }
  ```
  EOF
  type        = map(any)
}

variable "fw_instance_ips" {
  description = <<-EOF
  A map of FWs private IPs. IPs should be from the subnet set that the LB was created in.
  An example on how to feed this variable with data:

  ```hcl
  fw_instance_ips = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
  ```

  For format of `var.vmseries` check the `vmseries` module. Basically the key there is the VM name. By using that keys we can loop through all vmseries modules and take private IP from the interface that is assigned to the subnet we require. The subnet can be identified by the subnet set name (like above).
  EOF
  type        = map(any)
}

variable "tags" {
  description = "Map of AWS tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}