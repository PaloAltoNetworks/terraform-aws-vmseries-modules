module "security_vpc" {
  source = "../../modules/vpc"

  name                    = var.security_vpc_name
  cidr_block              = var.security_vpc_cidr
  vpc_endpoints           = var.security_vpc_endpoints
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"

  igw_is_next_hop_for = {
    "from-mgmt-to-igw" = {
      from_subnet_set = module.security_subnet_sets["mgmt"]
      to              = "0.0.0.0/0"
    }
    "from-natgw-to-igw" = {
      from_subnet_set = module.security_subnet_sets["natgw"]
      to              = "0.0.0.0/0"
    }
  }
}

module "security_subnet_sets" {
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name  = each.key
  vpc   = module.security_vpc
  cidrs = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

### NATGW ###

module "natgw" {
  module = "../../modules/nat_gateway"

  name       = var.nat_gateway_name
  subnet_set = module.security_subnet_set["natgw"]

  act_as_next_hop_for = {
    "from-gwlb-outbound-to-natgw" = {
      from_subnet_set = module.security_subnet_set["gwlb-outbound"]
      to              = var.summary_cidr_behind_natgw
    }
  }
}

### TGW ###

module transit_gateway {
  source = "../../modules/transit_gateway"

  name = var.transit_gateway_name
  asn  = var.transit_gateway_asn
  route_tables = {
    "security-in" = {
      create = true
      name   = "from-security-vpc"
    }
    "spoke-in" = {
      create = true
      name   = "from-spoke-vpcs"
    }
  }
}

# Open points:
#   - rename `act_as_next_hop_for` to `traffic_from`? 
#   - I wonder what was the use case for vpc_routes_additional? Search the repos which use modules/vpc_routes.

module transit_gateway_attachment {
  source = "../../modules/transit_gateway_attachment"

  name                        = var.security_transit_gateway_attachment
  subnet_set                  = module.security_subnet_sets["tgw-attach"]
  transit_gateway_route_table = module.transit_gateway.route_tables["security-in"]

  act_as_next_hop_for = {
    "from-gwlbe-outbound-to-tgw" = {
      from_subnet_set = module.security_subnet_sets["gwlbe-outbound"]
      to              = var.summary_cidr_behind_tgw
    }
    "from-gwlbe-eastwest-to-tgw" = {
      from_subnet_set = module.security_subnet_sets["gwlbe-eastwest"]
      to              = var.summary_cidr_behind_tgw
    }
  }
}

### GWLB ###

module "security_gwlb" {
  source = "../../modules/gateway_load_balancer"

  name             = var.gateway_load_balancer_name
  subnet_set       = module.security_subnet_sets["data"] # Assumption: one ss per gwlb.
  target_instances = module.vmseries.firewalls           # Takes an aws_instance.id and adds it to the aws_lb_target_group.
}

module "gwlbe_eastwest" {
  source = "../../modules/gateway_load_balancer_endpoint"

  name                  = var.gateway_load_balancer_endpoint_eastwest_name
  gateway_load_balancer = module.security_gwlb
  subnet_sets           = [module.security_subnet_set["gwlbe-eastwest"]]
  act_as_next_hop_for = {
    "from-tgw-to-gwlbe-eastwest" = {
      from_subnet_set = module.security_subnet_set["tgw-attach"]
      to              = var.summary_cidr_behind_tgw
    }
  }
}

module "gwlbe_outbound" {
  source = "../../modules/gateway_load_balancer_endpoint"

  name                  = var.gateway_load_balancer_endpoint_outbound_name
  gateway_load_balancer = module.security_gwlb
  subnet_sets           = [module.security_subnet_set["gwlbe-outbound"]]
  act_as_next_hop_for = {
    "from-natgw-to-gwlbe-outbound" = {
      from_subnet_set = module.security_subnet_set["natgw"]
      to              = var.summary_cidr_behind_gwlbe_outbound
    }
    "from-tgw-to-gwlbe-outbound" = {
      from_subnet_set = module.security_subnet_set["tgw-attach"]
      to              = var.summary_cidr_behind_gwlbe_outbound
    }
  }
}
