output vpc_id {
  value = module.vpc_all_options.vpc_id
}

output subnet_ids {
  value = module.vpc_all_options.subnet_ids
}

output route_table_ids {
  value = module.vpc_all_options.route_table_ids
}

output internet_gateway_id {
  value = module.vpc_all_options.internet_gateway_id
}

output nat_gateway_ids {
  value = module.vpc_all_options.nat_gateway_ids
}

output vpn_gateway_ids {
  value = module.vpc_all_options.vpn_gateway_ids
}

output security_group_ids {
  value = module.vpc_all_options.security_group_ids
}

output aws_vpc_endpoint_interface_ids {
  value = module.vpc_all_options.aws_vpc_endpoint_interface_ids
}