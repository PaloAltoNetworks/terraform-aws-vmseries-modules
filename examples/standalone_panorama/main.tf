locals {
  ssh_key_name = "${var.prefix}${var.panorama_ssh_key}"
}

# THIS PART IS NOT RECOMMENDED FOR PRODUCTION SERVICES IT IS FOR TESTING PURPOSES ONLY.
# When you create ssh-key pair like this, there potential security issue via statefile, this is major flaw and you NEVER
# should use it for production usage!

resource "tls_private_key" "rsa_panorama_key" {
  count = var.create_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  count = var.create_ssh_key ? 1 : 0

  key_name   = local.ssh_key_name
  public_key = tls_private_key.rsa_panorama_key[0].public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.rsa_panorama_key[0].private_key_pem}' > ./ssh_key_name.pem"
  }
}

#---------------------------------------------------------------------------------#

module "security_vpc" {
  source = "../../modules/vpc"

  cidr_block              = var.security_vpc_cidr
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
  name                    = "${var.prefix}${var.security_vpc_name}"
  security_groups         = var.security_vpc_security_groups
}

module "security_subnet_sets" {
  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
  has_secondary_cidrs = module.security_vpc.has_secondary_cidrs
  name                = each.key
  vpc_id              = module.security_vpc.id
}

locals {
  security_vpc_routes = concat(
    [
      for cidr in var.security_vpc_routes_outbound_destin_cidrs :
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

  availability_zone             = var.panorama_az
  create_public_ip              = var.panorama_create_public_ip
  create_read_only_iam_role     = var.panorama_enable_iam_read_only_policy
  ebs_volumes                   = var.panorama_ebs_volumes
  name                          = var.panorama_instance_name
  panorama_version              = var.panorama_version
  ssh_key_name                  = local.ssh_key_name
  subnet_id                     = module.security_subnet_sets["mgmt"].subnets[var.panorama_az].id
  universal_name_prefix         = var.prefix
  vpc_security_group_ids        = [module.security_vpc.security_group_ids["panorama_mgmt"]]
  create_custom_kms_key_for_ebs = var.panorama_create_custom_kms_key

  global_tags = var.global_tags
}