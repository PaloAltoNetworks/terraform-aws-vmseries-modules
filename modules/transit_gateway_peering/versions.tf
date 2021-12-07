terraform {
  required_version = ">= 0.15, < 2.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.10"
      configuration_aliases = [aws, aws.peer]
    }
  }
}
