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
  source = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.security_vpc.id
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

module "vmseries" {
  for_each = var.vmseries
  source   = "../../modules/vmseries"

  name              = var.name
  ssh_key_name      = var.ssh_key_name
  bootstrap_options = var.bootstrap_options
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
  source = "../../modules/alb"

  lb_name = "fosix-public-alb"
  region  = var.region

  subnets                    = { for k, v in module.security_subnet_sets["untrust"].subnets : k => { id = v.id } }
  desync_mitigation_mode     = "monitor"
  vpc_id                     = module.security_vpc.id
  configure_access_logs      = true
  access_logs_s3_bucket_name = "fosix-alb-logs-bucket"
  security_groups            = [module.security_vpc.security_group_ids["load_balancer"]]

  balance_rules = {
    "http-app" = {
      protocol = "HTTP"
      targets  = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
    }
    "https-app" = {
      protocol                         = "HTTPS"
      port                             = "444"
      health_check_port                = "80"
      health_check_healthy_threshold   = 2
      health_check_unhealthy_threshold = 10
      health_check_interval            = 10
      health_check_protocol            = "HTTP"
      health_check_matcher             = "200-301"
      health_check_path                = "/login.php"
      target_port                      = 8443
      round_robin                      = false

      certificate_arn = "arn:aws:acm:eu-west-1:354128141335:certificate/11e854e2-849d-443c-92fc-53327cf88e07"
      ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

      targets = { for k, v in var.vmseries : k => module.vmseries[k].interfaces["untrust"].private_ip }
    }
  }

  tags = var.global_tags
}

locals {
  security_vpc_routes = concat(
    [for subnet_key in ["mgmt", "untrust"] :
      {
        subnet_key   = subnet_key
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = var.security_vpc_routes_outbound_destin_cidrs
      }
    ],
  )
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : route.subnet_key => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.security_subnet_sets[each.key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}
