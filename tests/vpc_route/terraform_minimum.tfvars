region      = "us-east-1"
name_prefix = "test_vpc_route_"

security_vpc_cidr = "10.100.0.0/16"
security_vpc_subnets = {
  "10.100.0.0/24" = { az = "us-east-1a", set = "mgmt" }
  "10.100.1.0/24" = { az = "us-east-1a", set = "tgw_attach" }
  "10.100.2.0/24" = { az = "us-east-1a", set = "natgw" }
  "10.100.3.0/24" = { az = "us-east-1a", set = "gwlb" }
  "10.100.4.0/24" = { az = "us-east-1a", set = "gwlbe_inbound" }
}
security_vpc_security_groups = {
  vmseries_mgmt = {
    name = "vmseries_mgmt"
    rules = {
      all_outbound = {
        description = "Permit ALL outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH inbound"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}

security_vpc_mgmt_routes_to_igw = ["10.251.0.0/16", "10.252.0.0/16"]
security_vpc_app_routes_to_igw  = ["10.241.0.0/16", "10.242.0.0/16"]

transit_gateway_create = false
nat_gateway_create     = false
gwlb_create            = false
