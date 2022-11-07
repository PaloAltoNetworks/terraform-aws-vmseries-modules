data "aws_ebs_default_kms_key" "current" {
  count = var.panorama_ebs_encrypted ? 1 : 0
}

data "aws_kms_alias" "current_arn" {
  count = var.panorama_ebs_encrypted ? 1 : 0

  name = var.panorama_ebs_kms_key_alias != "" ? "alias/${var.panorama_ebs_kms_key_alias}" : data.aws_ebs_default_kms_key.current[0].key_arn
}

module "security_vpc" {
  source = "../../modules/vpc"

  cidr_block              = var.vpc_cidr
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
  name                    = "${var.name_prefix}${var.vpc_name}"
  security_groups         = var.vpc_security_groups
}

module "security_subnet_sets" {
  for_each = toset(distinct([for _, v in var.vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  cidrs               = { for k, v in var.vpc_subnets : k => v if v.set == each.key }
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  name                = each.key
  vpc_id              = module.security_vpc.id
}

locals {
  security_vpc_routes = concat(
    [
      for cidr in var.vpc_routes_outbound_destin_cidrs :
      {
        subnet_key   = "mgmt"
        next_hop_set = module.security_vpc.igw_as_next_hop_set
        to_cidr      = cidr
      }
    ],
  )
}

module "security_vpc_routes" {
  for_each = { for route in local.security_vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  next_hop_set    = each.value.next_hop_set
  route_table_ids = module.security_subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
}

module "panorama" {
  source = "../../modules/panorama"

  availability_zone      = var.panorama_az
  create_public_ip       = var.panorama_create_public_ip
  ebs_volumes            = var.panorama_ebs_volumes
  name                   = var.panorama_deployment_name
  ebs_kms_key_alias      = try(data.aws_kms_alias.current_arn[0].arn, null)
  panorama_version       = var.panorama_version
  ssh_key_name           = var.panorama_ssh_key_name
  subnet_id              = module.security_subnet_sets["mgmt"].subnets[var.panorama_az].id
  vpc_security_group_ids = [module.security_vpc.security_group_ids["panorama-mgmt"]]
  panorama_iam_role      = var.panorama_create_iam_instance_profile == false ? null : aws_iam_instance_profile.panorama_instance_profile[0].name

  global_tags = var.global_tags

  depends_on = [
    aws_iam_instance_profile.panorama_instance_profile
  ]
}
