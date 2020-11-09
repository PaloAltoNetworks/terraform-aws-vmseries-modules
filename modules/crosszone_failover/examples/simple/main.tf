data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.base_infra_state_bucket
    key = var.base_infra_state_key
    region = var.base_infra_region
  }
}

module "vmseries_crosszone_failover" {
  source                   = "../../"
  region                   = var.region
  tags                     = var.tags
  prefix_name_tag          = var.prefix_name_tag
  subnet_state = data.terraform_remote_state.vpc.outputs.subnets
  sg_state = data.terraform_remote_state.vpc.outputs.security_groups
  vpc_id = data.terraform_remote_state.vpc.outputs.vpcs["id"]
  lambda_s3_bucket = var.lambda_s3_bucket
  lambda_file_location = var.lambda_file_location
  lambda_file_name     = var.lambda_file_name
}
