output vpc_id {
  value = var.vpc.id
}

output names {
  value = { for k, v in local.subnets : k => try(v.tags.Name, null) }
}

output subnets {
  value = local.subnets
}

output route_tables {
  value = local.route_tables
}

output unique_route_table_ids {
  value = var.create_shared_route_table ? { "shared" = aws_route_table.shared["shared"].id } : { for k, v in aws_route_table.this : k => v.id }
}

output availability_zones {
  value = toset(keys(local.input_subnets))
}

output routing_cidrs {
  description = "Usable for vpc_route module. Example."
  value = { for k, v in local.subnets :
    v.cidr_block => "ipv4" if v.cidr_block != null && v.cidr_block != ""
  }
}

output ipv6_routing_cidrs {
  value = { for k, v in local.subnets :
    v.ipv6_cidr_block => "ipv6" if v.ipv6_cidr_block != null && v.ipv6_cidr_block != ""
  }
}
