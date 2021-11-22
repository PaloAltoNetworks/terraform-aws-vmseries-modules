# Palo Alto Networks VPC Route Module for AWS

A Terraform module for deploying a VPC route in AWS cloud.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name                    = var.name
  cidr_block              = var.vpc_cidr_block
  secondary_cidr_blocks   = var.vpc_secondary_cidr_blocks
  global_tags             = var.global_tags
  vpc_tags                = var.vpc_tags
  security_groups         = var.security_groups
}

module "subnet_sets" {
  source   = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.subnets : v.set]))
  
  name   = each.key
  cidrs  = { for k, v in var.subnets : k => v if v.set == each.key }
  vpc_id = module.vpc.id
}

module "nat_gateway_set" {
  source = "../../modules/nat_gateway_set"

  subnets = module.subnet_sets["natgw-1"].subnets
}

module "vpc_route" {
  source = "../../modules/vpc_route"

  for_each = {
    mgmt = {
      route_table_ids = module.subnet_sets["mgmt-1"].unique_route_table_ids
      next_hop_set    = module.vpc.igw_as_next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
    public = {
      route_table_ids = module.subnet_sets["public-1"].unique_route_table_ids
      next_hop_set    = module.nat_gateway_set.next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
    natgw = {
      route_table_ids = module.subnet_sets["natgw-1"].unique_route_table_ids
      next_hop_set    = module.vpc.igw_as_next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
  }

  route_table_ids = each.value.route_table_ids
  next_hop_set    = each.value.next_hop_set
  to_cidr         = each.value.to_cidr
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_type"></a> [cidr\_type](#input\_cidr\_type) | Type of `to_cidr`, either "ipv4" or "ipv6". | `string` | `"ipv4"` | no |
| <a name="input_next_hop_set"></a> [next\_hop\_set](#input\_next\_hop\_set) | The Next Hop Set object, such as an output `module.nat_gateway_set.next_hop_set`. The set of single-zone next hops should be specified as the `ids` map, in which case<br>each value is a next hop id and each key should be present among the keys of the input `route_table_ids`. To avoid unintended cross-zone routing, these keys should be equal. Example:<pre>next_hop_set = {<br>  type = "nat_gateway"<br>  id   = null<br>  ids  = {<br>    "us-east-1a" = "natgw-123"<br>    "us-east-1b" = "natgw-124"<br>  }<br>}</pre>For a non-AZ-aware next hop, such as an internet gateway, the `ids` map should be empty. All the route tables receive the same `id` of the next hop. Example:<pre>next_hop_set = {<br>  type = "internet_gateway"<br>  id   = "igw-12345"<br>  ids  = {}<br>}</pre> | <pre>object({<br>    type = string<br>    id   = string<br>    ids  = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_route_table_ids"></a> [route\_table\_ids](#input\_route\_table\_ids) | A map of Route Tables where to install the route. Each key is an arbitrary string,<br>each value is a Route Table identifier. The keys need to match keys used in the<br>`next_hop_set` input. The keys are usually Availability Zone names. Each of the Route Tables<br>obtains exactly one next hop from the `next_hop_set`. Example:<pre>route_table_ids = {<br>  "us-east-1a" = "rt-123123"<br>  "us-east-1b" = "rt-123456"<br>}</pre> | `map(string)` | n/a | yes |
| <a name="input_to_cidr"></a> [to\_cidr](#input\_to\_cidr) | The CIDR to match the packet's destination field. If they match, the route can be used for the packet. For example "0.0.0.0/0". | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
