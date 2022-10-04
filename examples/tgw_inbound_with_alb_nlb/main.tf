# ### SECURITY INFRASTRUCTURE PART ### #
# Two Next Generation Firewalls behind an Application and Network Load Balancers.

locals {
  # Create custom routes for the Security VPC.
  security_vpc_routes = concat(
    # Enable bi-directional communication with the internet for Management and Untrust subnets.
    [for subnet_key in ["mgmt", "untrust"] :
      {
        subnet_key   = subnet_key
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = "0.0.0.0/0"
      }
    ],
    # Direct traffic from Trust subnet to Transit Gateway
    [for cdir, subnet in var.app_vpc_subnets :
      {
        subnet_key   = "trust"
        next_hop_set = module.security_transit_gateway_attachment.next_hop_set
        to_cidr      = cdir
      } if subnet.set != "tgw"
    ]
  )

  # Normally, in the Network Load Balancer rules, each rule has it's own definition of targets.
  # In this example rules were simplified. They do not contain targets, as all of them are the Firewall VMs.
  # But since the targets are still required by the module, we need to add them now. 
  network_lb_rules = {
    for k, v in var.network_lb_rules : k => merge(v, {
      targets     = { for vmname, config in var.vmseries : vmname => module.vmseries[vmname].interfaces["untrust"].private_ip },
      target_type = "ip"
    })
  }
}

# ## SECURITY NETWORK ## #
# Create Security VPC components.
module "security_vpc" {
  source = "../../modules/vpc"

  name                    = "${var.name_prefix}${var.security_vpc_name}"
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "security_subnet_sets" {
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name         = "${var.name_prefix}${var.transit_gateway_name}"
  asn          = var.transit_gateway_asn
  route_tables = var.transit_gateway_route_tables
}

module "security_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = "${var.name_prefix}${var.security_vpc_tgw_attachment_name}"
  vpc_id                      = module.security_subnet_sets["tgw"].vpc_id
  subnets                     = module.security_subnet_sets["tgw"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["security_vpc"]
  propagate_routes_to = {
    app = module.transit_gateway.route_tables["spokes_vpc"].id
  }
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

# ## FIREWALL INFRASTRUCTURE ## #
# Create the firewalls and two Load Balancers in front of their's public network interfaces.
# The Application Load Balancer acts as a layer 7 Reverse Proxy for HTTP traffic.
# Where the Network Load Balancer is a layer 4 service. In this example it is used to Balance SSH traffic.
module "vmseries" {
  for_each = var.vmseries
  source   = "../../modules/vmseries"

  name              = "${var.name_prefix}${each.key}"
  ssh_key_name      = var.ssh_key_name
  bootstrap_options = var.bootstrap_options
  vmseries_version  = var.vmseries_version
  ebs_encrypted     = true
  interfaces = {
    mgmt = {
      device_index       = 0
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_mgmt"]]
      source_dest_check  = true
      subnet_id          = module.security_subnet_sets["mgmt"].subnets[each.value.az].id
      create_public_ip   = true
    }
    trust = {
      device_index       = 1
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_trust"]]
      source_dest_check  = true
      subnet_id          = module.security_subnet_sets["trust"].subnets[each.value.az].id
      create_public_ip   = false
    }
    untrust = {
      device_index       = 2
      security_group_ids = [module.security_vpc.security_group_ids["vmseries_untrust"]]
      source_dest_check  = true
      subnet_id          = module.security_subnet_sets["untrust"].subnets[each.value.az].id
      create_public_ip   = true
    }
  }

  tags = var.global_tags
}

module "public_nlb" {
  source = "../../modules/nlb"

  name                  = "${var.name_prefix}${var.network_lb_name}"
  create_dedicated_eips = true
  subnets               = { for k, v in module.security_subnet_sets["untrust"].subnets : k => { id = v.id } }
  vpc_id                = module.security_vpc.id
  balance_rules         = local.network_lb_rules

  tags = var.global_tags
}

module "public_alb" {
  source = "../../modules/alb"

  lb_name         = "${var.name_prefix}${var.application_lb_name}"
  subnets         = { for k, v in module.security_subnet_sets["untrust"].subnets : k => { id = v.id } }
  vpc_id          = module.security_vpc.id
  security_groups = [module.security_vpc.security_group_ids["application_load_balancer"]]
  rules           = var.application_lb_rules
  targets         = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }

  tags = var.global_tags
}
