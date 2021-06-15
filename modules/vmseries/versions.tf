terraform {
  required_version = ">= 0.13.6, < 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.24"
    }
  }
}
