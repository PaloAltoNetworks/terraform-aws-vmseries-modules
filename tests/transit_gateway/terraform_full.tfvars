region      = "us-east-1"
name_prefix = "test_tgw_"

transit_gateway_name = "tgw"
transit_gateway_asn  = "65200"
transit_gateway_route_tables = {
  "from_security_vpc" = {
    create = true
    name   = "from_security"
  }
  "from_spoke_vpc" = {
    create = true
    name   = "from_spokes"
  }
}
