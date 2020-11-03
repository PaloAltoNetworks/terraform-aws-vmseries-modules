output vpc_id {
  value = module.single_vpc.vpc_id
}

output subnet_ids {
  value = module.single_vpc.subnet_ids
}

output route_table_ids {
  value = module.single_vpc.route_table_ids
}

output internet_gateway_id {
  value = module.single_vpc.internet_gateway_id
}

output nat_gateway_ids {
  value = module.single_vpc.nat_gateway_ids
}

output vpn_gateway_ids {
  value = module.single_vpc.vpn_gateway_ids
}

output security_group_ids {
  value = module.single_vpc.security_group_ids
}

output aws_vpc_endpoint_interface_ids {
  value = module.single_vpc.aws_vpc_endpoint_interface_ids
}