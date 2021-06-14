terraform {
  required_version = ">= 0.12.30, < 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.10"
    }
  }
}
