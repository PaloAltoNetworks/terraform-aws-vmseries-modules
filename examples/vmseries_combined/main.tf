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
  source = "../../modules/nat_gateway"

  name       = var.nat_gateway_name
  subnet_set = module.security_subnet_sets["natgw"]
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

module transit_gateway_attachment {
  source = "../../modules/transit_gateway_attachment"

  name                        = var.security_transit_gateway_attachment
  subnet_set                  = module.security_subnet_sets["tgw-attach"]
  transit_gateway_route_table = module.transit_gateway.route_tables["security-in"]
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
  subnet_set            = module.security_subnet_sets["gwlbe-eastwest"]
}

module "gwlbe_outbound" {
  source = "../../modules/gateway_load_balancer_endpoint"

  name                  = var.gateway_load_balancer_endpoint_outbound_name
  gateway_load_balancer = module.security_gwlb
  subnet_set            = module.security_subnet_sets["gwlbe-outbound"]
}

module "security_route" {
  for_each = {
    "from-mgmt-to-igw" = {
      next_hop_set    = module.security_vpc.igw_as_next_hop_set
      route_table_ids = module.security_subnet_sets["mgmt"].unique_route_table_ids
      to              = "0.0.0.0/0"
    }
    "from-natgw-to-igw" = {
      next_hop_set    = module.security_vpc.igw_as_next_hop_set
      route_table_ids = module.security_subnet_sets["natgw"].unique_route_table_ids
      to              = "0.0.0.0/0"
    }
    "from-natgw-to-gwlbe-outbound" = {
      next_hop_set    = module.gwlbe_outbound.next_hop_set
      route_table_ids = module.security_subnet_sets["natgw"].unique_route_table_ids
      to              = var.summary_cidr_behind_tgw
    }
    "from-tgw-to-gwlbe-outbound" = {
      next_hop_set    = module.gwlbe_outbound.next_hop_set
      route_table_ids = module.security_subnet_sets["tgw-attach"].unique_route_table_ids
      to              = var.summary_cidr_behind_gwlbe_outbound
    }
    "from-gwlbe-outbound-to-natgw" = {
      next_hop_set    = module.natgw.next_hop_set
      route_table_ids = module.security_subnet_sets["gwlbe-outbound"].unique_route_table_ids
      to              = var.summary_cidr_behind_natgw
    }
    "from-gwlbe-outbound-to-tgw" = {
      next_hop_set    = module.transit_gateway_attachment.next_hop_set
      route_table_ids = module.security_subnet_sets["gwlbe-outbound"].unique_route_table_ids
      to              = var.summary_cidr_behind_tgw
    }
    "from-tgw-to-gwlbe-eastwest" = {
      next_hop_set    = module.gwlbe_eastwest.next_hop_set
      route_table_ids = module.security_subnet_sets["tgw-attach"].unique_route_table_ids
      to              = var.summary_cidr_behind_tgw
    }
    "from-gwlbe-eastwest-to-tgw" = {
      next_hop_set    = module.transit_gateway_attachment.next_hop_set
      route_table_ids = module.security_subnet_sets["gwlbe-eastwest"].unique_route_table_ids
      to              = var.summary_cidr_behind_tgw
    }
  }
  source = "../../modules/vpc_route"

  route_table_ids = each.value.route_table_ids
  to_cidrs        = { (each.value.to) = "ipv4" }
  next_hop_set    = each.value.next_hop_set
}

### App1 GWLB ###

# ...
# ...
# ... skipped a lot of code for app1_vpc
# ...
# ...

module "app1_vpc" {
  source = "../../modules/vpc"

  name                    = var.app1_vpc_name
  cidr_block              = var.app1_vpc_cidr
  vpc_endpoints           = {}
  security_groups         = var.app1_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "app1_subnet_sets" {
  for_each = toset(distinct([for _, v in var.app1_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name  = each.key
  vpc   = module.app1_vpc
  cidrs = { for k, v in var.app1_vpc_subnets : k => v if v.set == each.key }
}

module "app1_gwlbe_inbound" {
  source = "../../modules/gateway_load_balancer_endpoint"

  name                  = var.gateway_load_balancer_endpoint_app1_name
  gateway_load_balancer = module.security_gwlb # FIXME module.app1_gwlb
  subnet_set            = module.app1_subnet_sets["app1-gwlbe"]
  act_as_next_hop_for = {
    "from-igw-to-alb" = {
      route_table_id = module.app1_vpc.internet_gateway_route_table.id
      to_subnet_set  = module.app1_subnet_sets["app1-alb"]
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table.
    # In such IGW routes only the following destinations are allowed by AWS:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used above.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table

    # Aside: a VGW has the same rules, except it only supports individual NICs and no GWLBE (so, no balancing).
    # Looks like a temporary AWS limitation.
  }
}
