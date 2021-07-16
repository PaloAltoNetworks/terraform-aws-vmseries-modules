variable "name" {
  description = "Name of the VPC Endpoint Set, for example: \"my-gwlbe-\". Each individual endpoint is named by appending an AZ letter, such as \"my-set-a\" and \"my-set-b\". These names can be overriden using `custom_names`."
  default     = "gwlbe-"
  type        = string
}

variable "custom_names" {
  description = "Optional map of readable names of the VPC Endpoints, used to override the default naming generated from the input `name`. Each key is the Availability Zone identifier, for example `us-east-1b`. Each value is used as VPC Endpoint's standard AWS tag `Name`, for example \"my-gwlbe-in-us-east-1b\"."
  default     = {}
  type        = map(string)
}

variable "gwlb_service_name" {
  description = "The name of the VPC Endpoint Service to connect to, which may reside in a different VPC. Usually an output `module.gwlb.endpoint_service.service_name`. Example: \"com.amazonaws.vpce.eu-west-3.vpce-svc-0df5336455053eb2b\"."
  type        = string
}

variable "gwlb_service_type" {
  description = "The type of the Endpoint to create for `gwlb_service_name`."
  default     = "GatewayLoadBalancer"
  type        = string
}

variable "subnet_set" {
  description = "The result of the call to the `subnet_set` module: an object describing the Subnets to which the Endpoints should be attached. Exactly one VPC Endpoint is attached to each of the subnets in the set, under the same key. Importantly, the traffic returning from the Endpoint uses the Subnet's route table. Example: `subnet_set = module.my_subnet_set`"
  type = object({
    subnets = map(object({
      id = string
    }))
    vpc_id = string
  })
}

variable "act_as_next_hop_for" {
  description = <<-EOF
  The map of edge routes to create to pass network traffic to this VPC Endpoint Set.
  This input is not intended for typical routes - use instead the `vpc_route` module to pass traffic through this endpoint from sources other than IGW.
  This input only handles routes which have AZ-specific subnet CIDR destination, notably the ingress coming from an Internet Gateway (IGW).
  This special kind of routes is called ["edge routes"](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table) by AWS docs.
  The keys of the map are arbitrary strings. Example:
  ```
  act_as_next_hop_for = {
    "from-igw-to-alb" = {
      route_table_id = module.my_vpc.internet_gateway_route_table.id
      to_subnet_set  = module.my_alb_subnet_set
  }
  ```
  In this example, traffic from IGW destined to the ALB is instead routed to the GWLBE for inspection.
  EOF
  default     = {}
  type = map(object({
    route_table_id = string
    to_subnet_set = object({
      subnets = map(object({
        cidr_block = string
      }))
    })
  }))
}

variable "tags" {
  description = "AWS Tags for the VPC Endpoints."
  default     = {}
  type        = map(string)
}
