terraform {
  required_version = ">= 0.15, < 2.0" # 0.15 is the lowest version supporting `configuration_aliases`.
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.10"
      configuration_aliases = [aws, aws.remote]
    }
  }
}
