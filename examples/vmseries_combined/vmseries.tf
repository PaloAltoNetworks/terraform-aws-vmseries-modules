module "bootstrap" {
  source      = "../../modules/bootstrap"
  prefix      = var.prefix_name_tag
  global_tags = var.global_tags
}

module "vmseries" {
  source = "../../modules/vmseries"

  region     = var.region
  interfaces = var.interfaces
  firewalls = [for f in var.firewalls : merge(f, {
    # This iam_instance_profile cannot be in the tfvars.
    iam_instance_profile = module.bootstrap.instance_profile_name
    bootstrap_options = {
      mgmt-interface-swap             = "enable" # this can never be inside the bootstrap S3 bucket, because it tells which interface should reach S3 bucket
      vmseries-bootstrap-aws-s3bucket = module.bootstrap.bucket_name
    }
    })
  ]
  security_groups_map = module.security_vpc.security_group_ids
  prefix_name_tag     = var.prefix_name_tag
  tags                = var.global_tags
  ssh_key_name        = aws_key_pair.this.key_name
  fw_license_type     = var.fw_license_type
  fw_version          = var.fw_version
  fw_instance_type    = var.fw_instance_type

  # Because vmseries module does not yet handle subnet_set,
  # convert to a backward compatible map.
  subnets_map = { for v in flatten([for _, set in module.security_subnet_sets :
    [for _, subnet in set.subnets :
      {
        subnet = subnet
      }
    ]
  ]) : v.subnet.tags.Name => v.subnet.id }
}
