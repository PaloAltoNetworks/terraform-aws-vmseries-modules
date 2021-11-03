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
  # The notion of "set" is used a lot here, it extends to nat gateways, routes, routes' next hops,
  # gwlb endpoints and any other resources which would be a single point of failure when placed
  # in a single AZ.
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name   = each.key
  vpc_id = module.security_vpc.id
  cidrs  = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

### NATGW ###

module "natgw_set" {
  # This also a "set" and it means the same thing: we will repeat a nat gateway for each subnet (of the subnet_set).
  source = "../../modules/nat_gateway_set"

  subnets = module.security_subnet_sets["natgw"].subnets
}

### TGW ###

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name = var.transit_gateway_name
  asn  = var.transit_gateway_asn
  route_tables = {
    "from_security_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "${var.prefix_name_tag}from_spokes"
    }
  }
}

module "security_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = var.security_transit_gateway_attachment_name
  vpc_id                      = module.security_subnet_sets["tgw_attach"].vpc_id
  subnets                     = module.security_subnet_sets["tgw_attach"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["from_security_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["from_spoke_vpc"].id
  }
}

resource "aws_ec2_transit_gateway_route" "from_spokes_to_security" {
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_spoke_vpc"].id
  # Next hop.
  transit_gateway_attachment_id = module.security_transit_gateway_attachment.attachment.id
  # Inspect every packet egressing spokes without exception.
  destination_cidr_block = "0.0.0.0/0"
  blackhole              = false
}

### GWLB ###

module "security_gwlb" {
  source = "../../modules/gwlb"

  name    = var.gwlb_name
  vpc_id  = module.security_subnet_sets["gwlb"].vpc_id
  subnets = module.security_subnet_sets["gwlb"].subnets

  target_instances = module.vmseries.firewalls
}

module "gwlbe_eastwest" {
  source = "../../modules/gwlb_endpoint_set"

  name              = var.gwlb_endpoint_set_eastwest_name
  gwlb_service_name = module.security_gwlb.endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_eastwest"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_eastwest"].subnets
}

module "gwlbe_outbound" {
  source = "../../modules/gwlb_endpoint_set"

  name              = var.gwlb_endpoint_set_outbound_name
  gwlb_service_name = module.security_gwlb.endpoint_service.service_name
  vpc_id            = module.security_subnet_sets["gwlbe_outbound"].vpc_id
  subnets           = module.security_subnet_sets["gwlbe_outbound"].subnets
}


locals {
  security_vpc_routes = concat(
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in concat(var.security_vpc_routes_eastwest_cidrs, var.security_vpc_mgmt_routes_to_tgw) :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_eastwest_cidrs :
      {
        subnet_key   = "tgw_attach"
        next_hop_set = module.gwlbe_eastwest.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "tgw_attach"
        next_hop_set = module.gwlbe_outbound.next_hop_set
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
        subnet_key   = "gwlbe_outbound"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cidr
      }
    ],
    [for cidr in var.security_vpc_routes_eastwest_cidrs :
      {
        subnet_key   = "gwlbe_eastwest"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
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
    [for cidr in var.security_vpc_routes_outbound_source_cidrs :
      {
        subnet_key   = "natgw"
        next_hop_set = module.gwlbe_outbound.next_hop_set
        to_cidr      = cidr
      }
    ],
  )
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}
