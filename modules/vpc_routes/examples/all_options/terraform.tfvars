region = "us-east-1"

prefix_name_tag = "vpc-all-options-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Group       = "SecOps"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}


vpc_routes = {
  mgmt-igw = {
    route_table   = "mgmt"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "igw"
  }
  # mgmt-tgw       = { 
  #   route_table = "mgmt"
  #   prefix = "10.0.0.0/8"
  #   next_hop_type = "transit_gateway"
  #   next_hop_name = "my-tgw"
  # }
  mgmt-vgw = {
    route_table   = "mgmt"
    prefix        = "172.16.0.0/12"
    next_hop_type = "vpn_gateway"
    next_hop_name = "vmseries_vgw"
  }
  public-igw = {
    route_table   = "public"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "igw"
  }
}
