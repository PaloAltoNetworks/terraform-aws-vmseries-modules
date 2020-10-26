provider "aws" {
  region  = var.region
  version = "3.8.0"
  profile = "default"
}

module "bootstrap" {
  source           = "./.."
  prefix    = var.prefix
  
}

output bucket_id { value = module.bootstrap.bucket_id }
output bucket_name { value = module.bootstrap.bucket_name }
output instance_profile_name { value = module.bootstrap.instance_profile_name }
