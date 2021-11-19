region = "us-east-1"

prefix_name_tag = "vpc-all-options-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Group       = "SecOps"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

## Current example set to work from remote state,
//TODO: Generalize inputs

base_infra_state_bucket = "foo"
base_infra_state_key    = "bar"
base_infra_region       = "us-east-1"

lambda_s3_bucket     = "foo"
lambda_file_location = "lambda-package"
lambda_file_name     = "crosszone_ha_instance_id.zip"