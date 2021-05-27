variable "vpc_id" {
  type        = string
  description = "Identifier of the pre-existing VPC to create the ELB resources in."
}

variable "global_tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags (key / value pairs) to apply to all resources."
}

variable "elb_subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs to be used as targets for all ELBs"
}

variable "target_instance_ids" {
  type        = list(string)
  description = "List of Instance IDs of VM-Series (with interface swap enabled) to be used as targets for all ELBs"
}

variable "nlbs" {
  type        = any
  default     = {}
  description = <<EOF
Nested Map of AWS Network Load balancers to create and the "apps" (target groups, listeners) associated with each.

-> nlb map key (string) :  Unique reference for each NLB. Only used to reference resources inside of terraform
--> `name` (string) : Name of NLB (ELB Names in AWS are not tag based, changing name is destructive)
--> `internal` (bool) : Default `false`. Set to `true` to create an internal NLB.
--> `enable_cross_zone_load_balancing` (bool) :  Default `true`. Set to `false` to disable.
--> `eips` (bool) : Set `true` to create static EIPs for the NLB
--> `apps` (map) :  Nested map of "apps" associated with this NLB
---> apps map key (string) :  Unique reference for each app of this NLB. Only used to reference resources inside of terraform
----> `name` (string) : Name Tag for the Target Group
----> `protocol` (string) : `TCP`, `TLS`, `UDP`, or `TCP_UDP`
----> `listener_port` (string) :  Port for the NLB listener
----> `target_port` (string) :  Port for the target group for VM-Series translation. Typically will be unique per app

Example:
```
nlbs = {
  nlb01 = {
    name                             = "nlb01-inbound"
    internal                         = false
    eips                             = true
    enable_cross_zone_load_balancing = true
    apps = {
      app01 = {
        name          = "inbound-nlb01-app01-ssh"
        protocol      = "TCP"
        listener_port = "22"
        target_port   = "5001"
      }
      app02 = {
        name          = "inbound-nlb01-app02-https"
        protocol      = "TCP"
        listener_port = "443"
        target_port   = "5002"
      }
    }
  }
```
EOF
}


variable "albs" {
  type        = map(any)
  default     = {}
  description = "Nested Map of Application Load balancers to create and the apps associated with each. See README for details."
}
