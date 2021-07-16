resource "aws_vpc_endpoint" "this" {
  for_each = var.subnet_set.subnets

  # "Only one subnet can be specified for GatewayLoadBalancer" as AWS helpfully says in an error msg. But it still is a one-item set.
  subnet_ids        = toset([each.value.id])
  vpc_id            = var.subnet_set.vpc_id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = var.gwlb_service_type
  tags              = merge(var.tags, { Name = lookup(var.custom_names, each.key, "${var.name}${substr(each.key, -1, -1)}") })

  lifecycle {
    # Workaround for error "InvalidParameter: Endpoint must be removed from route table before deletion".
    create_before_destroy = true
  }
}

locals {
  input_routes_flat = flatten([for routekey, route in var.act_as_next_hop_for :
    [for subnetkey, subnet in route.to_subnet_set.subnets :
      {
        routekey  = routekey
        route     = route
        subnetkey = subnetkey
        subnet    = subnet
      }
    ]
  ])
  input_routes = { for v in local.input_routes_flat : "${v.routekey}-${v.subnetkey}" => v }
}

resource "aws_route" "this" {
  for_each = local.input_routes

  route_table_id         = each.value.route.route_table_id
  vpc_endpoint_id        = aws_vpc_endpoint.this[each.value.subnetkey].id
  destination_cidr_block = each.value.subnet.cidr_block
  # The route matches the exact cidr of a subnet, no less and no more.
  # Routes like these are special in that they are on the "edge", that is they are part of an IGW route table,
  # and AWS allows their destinations to only be:
  #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
  #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
  # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table

  # Aside: a VGW has the same rules, except it only supports individual NICs but not GWLB. Such lack
  # of GWLB balancing looks like a temporary AWS limitation.
}
