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

variable "vpc_id" {
  description = "AWS identifier of a VPC containing the Endpoint."
  type        = string
}

variable "subnets" {
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
  type = map(object({
    id = string
  }))
}

variable "act_as_next_hop_for" {
  description = <<-EOF
  The map of edge routes to create to pass network traffic to this Endpoint Set.
  This input is not intended for typical routes - use instead the `vpc_route` module to pass traffic through this Endpoint Set from sources other than IGW.
  This input only handles routes which have subnet CIDRs destination (AZ-specific), usually the ingress traffic coming from an Internet Gateway.
  AWS docs call this special kind of route the ["edge route"](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table).
  The keys of the map are arbitrary strings. Example:
  ```
  act_as_next_hop_for = {
    from_igw_to_alb = {
      route_table_id = module.my_vpc.internet_gateway_route_table.id
      to_subnets     = module.my_alb_subnet_set.subnets
  }
  ```
  In this example, traffic from IGW destined to the ALB is instead routed to the GWLBE (for inspection by an appliance).
  EOF
  default     = {}
  type = map(object({
    route_table_id = string
    to_subnets = map(object({
      cidr_block = string
    }))
  }))
}

variable "tags" {
  description = "AWS Tags for the VPC Endpoints."
  default     = {}
  type        = map(string)
}
