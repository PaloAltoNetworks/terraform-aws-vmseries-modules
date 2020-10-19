############################################################
# Output of simple name -> ID mappings in correct format to be referenced in other modules
############################################################

output vpc_id {
  description = "VPC Name -> ID Map (New OR Existing)"
  value       = local.combined_vpc
}

output subnet_ids {
  description = "Subnets Name -> ID Map (New AND Existing)"
  value       = local.combined_subnets
}

output route_table_ids {
  description = "Route Tables Name -> ID Map (New)"
  value = {
    for k, route_table in aws_route_table.this :
    k => route_table.id
  }
}

output internet_gateway_id {
  description = "Internet Gateway Name -> ID Map (New)"
  value = {
    for k, igw in aws_internet_gateway.this :
    k => igw.id
  }
}

output nat_gateway_ids {
  description = "NAT Gateway Name -> ID Map (New)"
  value = {
    for k, nat_gw in aws_nat_gateway.this :
    k => nat_gw.id
  }
}

output vpn_gateway_ids {
  description = "VPN Gateway Name -> ID Map (New)"
  value = {
    for k, vpn_gw in aws_vpn_gateway.this :
    k => vpn_gw.id
  }
}

output security_group_ids {
  description = "Security Group Name -> ID Map (New)"
  value = {
    for k, sg in aws_security_group.this :
    k => sg.id
  }
}

output aws_vpc_endpoint_interface_ids {
  description = "Interface VPC Endpoint Name -> ID Map (New)"
  value = {
    for k, endpoint in aws_vpc_endpoint.interface :
    k => endpoint.id
  }
}


