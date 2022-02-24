variable "name" {
  default = null
  type    = string
}

variable "vpc_id" {
  type = string
}

variable "type" {
  description = <<-EOF
  The type of the service.
  The type "Gateway" does not tolerate inputs `subnets`,  `security_group_ids`, and `private_dns_enabled`.
  The type "Interface" does not tolerate input `route_table_ids`.
  The type "GatewayLoadBalancer" is similar to "Gateway", but can be deployed with the dedicated module `gwlb_endpoint_set`.
  If null, "Gateway" is used by default.
  EOF
  type        = string
}

variable "create" {
  description = "If false, does not create a new AWS VPC Endpoint, but instead uses a pre-existing one. The inputs `name`, `service_name`, `simple_service_name`, `tags`, `type`, and `vpc_id` can be used to match the pre-existing endpoint."
  default     = true
  type        = bool
}

variable "service_name" {
  description = "The exact service name. This input is ignored if `simple_service_name` is defined. Typically \"com.amazonaws.<region>.<service>\", for example: \"com.amazonaws.us-west-2.s3\""
  default     = null
  type        = string
}

variable "simple_service_name" {
  description = "The simplified service name for AWS service, for example: \"s3\". Uses the service from the current region. If null, the `service_name` input is used instead."
  default     = null
  type        = string
}

variable "auto_accept" {
  description = "If a service connection requires service owner's acceptance, the request will be approved automatically, provided that both parties are members of the same AWS account."
  default     = null
  type        = bool
}

variable "policy" {
  default = null
  type    = string
}

variable "private_dns_enabled" {
  default = null
  type    = bool
}

variable "security_group_ids" {
  default = []
  type    = list(string)
}

variable "subnets" {
  # Description identical as in modules/gwlb_endpoint_set:
  description = <<-EOF
  Map of Subnets where to create the Endpoints. Each map's key is the availability zone name and each map's object has an attribute
  `id` identifying AWS Subnet. Importantly, the traffic returning from the Endpoint uses the Subnet's route table.
  The keys of this input map are used for the output map `endpoints`.
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
  default     = {}
  type = map(object({
    id = string
  }))
}

variable "route_table_ids" {
  default = {}
  type    = map(string)
}

variable "tags" {
  default = {}
  type    = map(string)
}

