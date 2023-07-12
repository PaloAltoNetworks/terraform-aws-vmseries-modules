variable "name" {
  description = "Name of the created GWLB and its Target Group. Must be unique per AWS region per AWS account."
  type        = string
}

variable "vpc_id" {
  description = "AWS identifier of a VPC containing the Endpoint."
  type        = string
}

variable "subnets" {
  description = <<-EOF
  Map of subnets where to create the GWLB. Each map's key is the availability zone name and each map's object has an attribute
  `id` identifying AWS subnet.
  Example for users of module `subnet_set`:
  ```
  subnets = module.subnet_set.subnets
  ```
  Example:
  ```
  subnets = {
    "us-east-1a" = { id = "snet-123007" }
    "us-east-1b" = { id = "snet-123008" }
  }
  ```
  EOF
  type = map(object({
    id = string
  }))
}

variable "target_instances" {
  description = "Map of instances to attach to the GWLB Target Group."
  default     = {}
  type = map(object({
    id = string
  }))
}

variable "allowed_principals" {
  description = "List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. For example `[\"arn:aws:iam::123456789000:root\"]`."
  default     = []
  type        = list(string)
}

##### Healthcheck #####

variable "deregistration_delay" {
  description = "See the `aws` provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#deregistration_delay)."
  default     = null
  type        = number
}

variable "health_check_enabled" {
  description = "See the `aws` provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#health_check)."
  default     = null
  type        = bool
}

variable "health_check_interval" {
  description = "Approximate amount of time, in seconds, between health checks of an individual target. Minimum 5 and maximum 300 seconds."
  default     = 5 # override the AWS default of 10 seconds
  type        = number
}

variable "health_check_matcher" {
  description = "See the `aws` provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#health_check)."
  default     = null
  type        = string
}

variable "health_check_path" {
  description = "See the `aws` provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#health_check)."
  default     = null
  type        = string
}

variable "health_check_port" {
  description = "The port on a target to which the load balancer sends health checks."
  default     = 80
  type        = number
}

variable "health_check_protocol" {
  description = "Protocol to use when communicating with `health_check_port`. Either HTTP, HTTPS, or TCP."
  default     = "TCP"
  type        = string
}

variable "health_check_timeout" {
  description = "After how many seconds to consider the health check as failed without a response. Minimum 2 and maximum 120. Required to be `null` when `health_check_protocol` is TCP."
  default     = null
  type        = number
}

variable "healthy_threshold" {
  description = "The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10."
  default     = 3
  type        = number
}

variable "unhealthy_threshold" {
  description = "The number of failed health checks required before a healthy target becomes unhealthy. Minimum 2 and maximum 10."
  default     = 3
  type        = number
}

variable "stickiness_type" {
  description = <<-EOF
  If `stickiness_type` is `null`, then attribute `enabled` is set to `false` in stickiness configuration block,
  value provided in `type` is ignored and by default the Gateway Load Balancer uses 5-tuple to maintain flow stickiness to a specific target appliance.
  If `stickiness_type` is not `null`, then attribute `enabled` is set to `true` in stickiness configuration block
  and the stickiness `type` can be then customized by using value:
  - `source_ip_dest_ip_proto` for 3-tuple (Source IP, Destination IP and Transport Protocol)
  - `source_ip_dest_ip` for 2-tuple (Source IP and Destination IP)
  ```
  EOF
  default     = null
  type        = string

  validation {
    condition     = (var.stickiness_type == null || contains(["source_ip_dest_ip", "source_ip_dest_ip_proto"], coalesce(var.stickiness_type, "source_ip_dest_ip_proto")))
    error_message = "The stickiness_type value must be `null`, `source_ip_dest_ip` or `source_ip_dest_ip_proto`."
  }
}

##### Various categories of Tags #####

variable "lb_tags" {
  description = "Map of AWS tags to apply to the created Load Balancer object. These tags are applied after the `global_tags`."
  default     = {}
  type        = map(string)
}

variable "lb_target_group_tags" {
  description = "Map of AWS tags to apply to the created GWLB Target Group. These tags are applied after the `global_tags`."
  default     = {}
  type        = map(string)
}

variable "endpoint_service_tags" {
  description = "Map of AWS tags to apply to the created GWLB Endpoint Service. These tags are applied after the `global_tags`."
  default     = {}
  type        = map(string)
}

variable "global_tags" {
  description = "Map of AWS tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}


variable "enable_lb_deletion_protection" {
  description = <<-EOF
  Whether to enable deletion protection on the gateway loadbalancer.
  EOF
  default     = false
  type        = bool
}
