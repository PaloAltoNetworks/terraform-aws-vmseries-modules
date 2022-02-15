terraform {
  required_version = ">= 0.13.7, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.67" # Could be moved down as far as 3.24.1 probably, which contains https://github.com/hashicorp/terraform-provider-aws/issues/15474
    }
  }
}

provider "aws" {
  region                  = var.region
  access_key              = var.aws_access_key
  secret_key              = var.aws_secret_key
  shared_credentials_file = var.aws_shared_credentials_file
  profile                 = var.aws_profile
  dynamic "assume_role" {
    for_each = { for k in ["one"] : k => var.aws_assume_role if var.aws_assume_role != null }

    content {
      role_arn     = assume_role.value.role_arn
      session_name = assume_role.value.session_name
      external_id  = assume_role.value.external_id
    }
  }
}
