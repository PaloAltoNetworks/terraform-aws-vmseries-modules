terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.17"
      configuration_aliases = [aws, aws.remote]
    }
  }
}

provider "aws" {
  alias = "remote"
}
