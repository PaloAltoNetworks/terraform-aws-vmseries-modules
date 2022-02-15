# AWS GWLB Endpoint Set

This module creates a set of [VPC GWLB Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-gateway-load-balancer.html)
over a range of one or more Availability Zones. All the Endpoints transfer the traffic to the same Gateway Load Balancer (GWLB).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.18 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_act_as_next_hop_for"></a> [act\_as\_next\_hop\_for](#input\_act\_as\_next\_hop\_for) | The map of edge routes to create to pass network traffic to this Endpoint Set.<br>This input is not intended for typical routes - use instead the `vpc_route` module to pass traffic through this Endpoint Set from sources other than IGW.<br>This input only handles routes which have subnet CIDRs destination (AZ-specific), usually the ingress traffic coming from an Internet Gateway.<br>AWS docs call this special kind of route the ["edge route"](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table).<br>The keys of the map are arbitrary strings. Example:<pre>act_as_next_hop_for = {<br>  from_igw_to_alb = {<br>    route_table_id = module.my_vpc.internet_gateway_route_table.id<br>    to_subnets     = module.my_alb_subnet_set.subnets<br>}</pre>In this example, traffic from IGW destined to the ALB is instead routed to the GWLBE (for inspection by an appliance). | <pre>map(object({<br>    route_table_id = string<br>    to_subnets = map(object({<br>      cidr_block = string<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_custom_names"></a> [custom\_names](#input\_custom\_names) | Optional map of readable names of the VPC Endpoints, used to override the default naming generated from the input `name`. Each key is the Availability Zone identifier, for example `us-east-1b`. Each value is used as VPC Endpoint's standard AWS tag `Name`, for example "my-gwlbe-in-us-east-1b". | `map(string)` | `{}` | no |
| <a name="input_gwlb_service_name"></a> [gwlb\_service\_name](#input\_gwlb\_service\_name) | The name of the VPC Endpoint Service to connect to, which may reside in a different VPC. Usually an output `module.gwlb.endpoint_service.service_name`. Example: "com.amazonaws.vpce.eu-west-3.vpce-svc-0df5336455053eb2b". | `string` | n/a | yes |
| <a name="input_gwlb_service_type"></a> [gwlb\_service\_type](#input\_gwlb\_service\_type) | The type of the Endpoint to create for `gwlb_service_name`. | `string` | `"GatewayLoadBalancer"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC Endpoint Set, for example: "my-gwlbe-". Each individual endpoint is named by appending an AZ letter, such as "my-set-a" and "my-set-b". These names can be overriden using `custom_names`. | `string` | `"gwlbe-"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of Subnets where to create the Endpoints. Each map's key is the availability zone name and each map's object has an attribute<br>`id` identifying AWS Subnet. Importantly, the traffic returning from the Endpoint uses the Subnet's route table.<br>The keys of this input map are used for the output map `endpoints`.<br>Example for users of module `subnet_set`:<pre>subnets = module.subnet_set.subnets</pre>Example:<pre>subnets = {<br>  "us-east-1a" = { id = "snet-123007" }<br>  "us-east-1b" = { id = "snet-123008" }<br>}</pre> | <pre>map(object({<br>    id = string<br>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS Tags for the VPC Endpoints. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS identifier of a VPC containing the Endpoint. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Map of the created endpoints. The keys are the same as the keys of the input `subnets`. |
| <a name="output_next_hop_set"></a> [next\_hop\_set](#output\_next\_hop\_set) | The Next Hop Set object, useful as an input to the `vpc_route` module. The intention would<br>be to route traffic from subnets to endpoints while preventing cross-AZ traffic (so<br>that a subnet in AZ-a only routes to an endpoint in AZ-a). Example:<pre>next_hop_set = {<br>  ids = {<br>    "us-east-1a" = "gwlbe-0ddf598f93a8ea8ae"<br>    "us-east-1b" = "gwlbe-0862c4b707b012111"<br>  }<br>  id   = null<br>  type = "vpc_endpoint"<br>}</pre> |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
