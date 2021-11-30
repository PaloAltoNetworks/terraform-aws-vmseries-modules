module "vpc" {
  source = "../../modules/vpc"

  name                    = "${var.prefix_name_tag}vpc"
  cidr_block              = var.cidr_block
  create_internet_gateway = true
  global_tags             = var.global_tags
  security_groups         = var.security_groups
}

module "subnet_sets" {
  for_each = toset(distinct([for _, v in var.subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  cidrs               = { for k, v in var.subnets : k => v if v.set == each.key }
  vpc_id              = module.vpc.id
  has_secondary_cidrs = module.vpc.has_secondary_cidrs
}

module "vpc_route" {
  source = "../../modules/vpc_route"

  route_table_ids = module.subnet_sets["mgmt-1"].unique_route_table_ids
  next_hop_set    = module.vpc.igw_as_next_hop_set
  to_cidr         = "0.0.0.0/0"
}


module "bootstrap" {
  source = "../../modules/bootstrap"
  prefix = var.prefix_name_tag

  hostname = "${var.prefix_name_tag}vmseries1"
  # panorama-server
  # panorama-server2
  # tplname
  # dgname
  # vm-auth-key
  # op-command-modes
}

locals {
  # Because vmseries module does not yet handle subnet_set,
  # convert to a backward compatible map.
  subnets_map = { for v in flatten([for _, set in module.subnet_sets :
    [for _, subnet in set.subnets :
      {
        subnet = subnet
      }
    ]
  ]) : v.subnet.tags.Name => v.subnet.id }


  firewalls = [for f in var.firewalls : merge(f, {
    iam_instance_profile = module.bootstrap.instance_profile_name
    bootstrap_options = {
      vmseries-bootstrap-aws-s3bucket = module.bootstrap.bucket_name
    }
  })]

}

module "vmseries" {
  source = "../../modules/vmseries"

  region              = var.region
  security_groups_map = module.vpc.security_group_ids
  prefix_name_tag     = var.prefix_name_tag
  interfaces          = var.interfaces
  tags                = var.global_tags
  ssh_key_name        = var.ssh_key_name
  firewalls           = local.firewalls
  fw_license_type     = var.fw_license_type
  fw_version          = var.fw_version
  fw_instance_type    = var.fw_instance_type
  subnets_map         = local.subnets_map
}
