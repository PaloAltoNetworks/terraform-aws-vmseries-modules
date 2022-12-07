locals {
  mpl_id = var.managed_prefix_list != null ? aws_ec2_managed_prefix_list.this[0].id : var.managed_prefix_list_id
}

resource "aws_route" "this" {
  for_each = var.route_table_ids

  route_table_id              = each.value
  destination_cidr_block      = var.cidr_type == "ipv4" ? var.to_cidr : null
  destination_ipv6_cidr_block = var.cidr_type == "ipv6" ? var.to_cidr : null
  destination_prefix_list_id  = var.cidr_type == "mpl" ? local.mpl_id : null
  # carrier_gateway_id would require aws provider version ~> 3.35

  transit_gateway_id        = var.next_hop_set.type == "transit_gateway" ? var.next_hop_set.id : null
  gateway_id                = var.next_hop_set.type == "internet_gateway" || var.next_hop_set.type == "vpn_gateway" ? var.next_hop_set.id : null
  nat_gateway_id            = var.next_hop_set.type == "nat_gateway" ? var.next_hop_set.ids[each.key] : null
  network_interface_id      = var.next_hop_set.type == "interface" ? var.next_hop_set.ids[each.key] : null
  vpc_endpoint_id           = var.next_hop_set.type == "vpc_endpoint" ? var.next_hop_set.ids[each.key] : null
  vpc_peering_connection_id = var.next_hop_set.type == "vpc_peer" ? var.next_hop_set.id : null
  egress_only_gateway_id    = var.next_hop_set.type == "egress_only_gateway" ? var.next_hop_set.id : null # for non-SNAT IPv6 egress only
  local_gateway_id          = var.next_hop_set.type == "local_gateway" ? var.next_hop_set.id : null       # for an AWS Outpost only
}

resource "aws_ec2_managed_prefix_list" "this" {
  count          = var.managed_prefix_list != null ? 1 : 0
  name           = var.managed_prefix_list.name
  address_family = "IPv4"
  max_entries    = var.managed_prefix_list.max_entries

  dynamic "entry" {
    for_each = var.managed_prefix_list.entries
    content {
      cidr        = entry.value["cidr"]
      description = entry.value["description"]
    }
  }
}
