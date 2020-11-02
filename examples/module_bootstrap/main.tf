module "bootstrap" {
  source = "../../modules/bootstrap"
  prefix = var.prefix
}

output bucket_id { value = module.bootstrap.bucket_id }
output bucket_name { value = module.bootstrap.bucket_name }
output instance_profile_name { value = module.bootstrap.instance_profile_name }
