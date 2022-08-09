module "security_vpc" {
  source = "../../modules/vpc"

  name                    = var.security_vpc_name
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "security_subnet_sets" {
  # The "set" here means we will repeat in each AZ an identical/similar subnet.
  # The notion of "set" is used a lot here, it extends to routes, routes' next hops,
  # gwlb endpoints and any other resources which would be a single point of failure when placed
  # in a single AZ.
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
  source = "../../modules/nat_gateway_set"

  subnets = module.security_subnet_sets["natgw"].subnets
}

# Gateway Load Balancer
module "security_gwlb" {
  source = "../../modules/gwlb"

  name    = var.gwlb_name
  vpc_id  = module.security_subnet_sets["gwlb"].vpc_id
  subnets = module.security_subnet_sets["gwlb"].subnets

  target_instances = { for k, v in module.vmseries : k => { id = v.instance.id } }
}

# Gateway Load Balancer Endpoints
module "gwlbe_outbound" {
  source = "../../modules/gwlb_endpoint_set"

  name              = var.gwlb_endpoint_set_outbound_name
  gwlb_service_name = module.security_gwlb.endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_outbound"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_outbound"].subnets
}

# VM-Series
module "vmseries" {
  source = "../../modules/vmseries"

  for_each = var.firewalls

  name              = each.key
  tags              = var.global_tags
  ssh_key_name      = var.ssh_key_name
  bootstrap_options = local.bootstrap_options
  vmseries_version  = var.vmseries_version

  interfaces = {
    data = {
      device_index       = 0
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_data"]]
      source_dest_check  = false
      subnet_id          = module.security_subnet_sets["data"].subnets[each.value.az].id
      create_public_ip   = false
    }
    mgmt = {
      device_index       = 1
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_mgmt"]]
      source_dest_check  = true
      subnet_id          = module.security_subnet_sets["mgmt"].subnets[each.value.az].id
      create_public_ip   = true
    }
    untrust = {
      device_index       = 2
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_untrust"]]
      source_dest_check  = false
      subnet_id          = module.security_subnet_sets["untrust"].subnets[each.value.az].id
      create_public_ip   = true
    }
  }
}

locals {
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "untrust"
        next_hop_set = module.natgw_set.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "natgw"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "gwlbe_outbound"
        next_hop_set = module.natgw_set.next_hop_set
        to_cidr      = cidr
      }
    ],

    [for cidr in var.security_vpc_routes_outbound_source_cidrs :
      {
        subnet_key   = "natgw"
        next_hop_set = module.gwlbe_outbound.next_hop_set
        to_cidr      = cidr
      }
    ],
  )

  outbound = [for k, v in module.gwlbe_outbound.endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, var.outbound_subinterface)]

  bootstrap_options = join(";", compact(concat(
    [var.bootstrap_options],
    [for _, v in local.outbound : "${v}"]
  )))
}

# Security VPC Routes
module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}
