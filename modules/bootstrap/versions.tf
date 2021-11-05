terraform {
  required_version = ">= 0.13.7, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}
