region = "us-east-1"

prefix_name_tag = "tgw-module-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

transit_gateways = {
  prod = {
    name              = "prod"
    local_tags        = { "foo" = "bar" }
    asn               = "65301",
    shared_principals = ["123456789012"]
    route_tables = {
      security = { name = "security-in", local_tags = { "foo" = "bar" } },
      spoke    = { name = "spoke-in" }
    }
  },
  existing = { // Example of brownfield support for existing TGW and TGW route table
    name     = "foo"
    existing = true
    route_tables = {
      security = { name = "bar", existing = true },
    }
  }
}

transit_gateway_vpc_attachments = {
  prod = {
    name                                    = "prod-security"
    local_tags                              = { "foo" = "bar" }
    vpc                                     = "foo"
    subnets                                 = ["foo", "bar"]
    transit_gateway                         = "prod"
    transit_gateway_route_table_association = "security"
  }
}

// TODO: Not yet implemented with new data model

# transit_gw_peerings = {
#   prod    = { 
#     tgw_rt_association      = "prod-security-in"
#     peer_account_id         = "123456789012"
#     peer_region             = "us-gov-west-1"
#     peer_transit_gateway_id = "tgw-123456789012"
#     peer_tgw_rt_association = "tgw-rtb-123456789012"
#     same_account_accepter   =  true }     
# }