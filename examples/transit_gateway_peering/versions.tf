terraform {
  required_version = ">= 0.13.7, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.50" # Could be moved down as far as 3.24.1 probably, which contains https://github.com/hashicorp/terraform-provider-aws/issues/15474
    }
  }
}
