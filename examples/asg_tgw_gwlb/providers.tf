terraform {
  required_version = ">= 0.15.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25"
    }
  }
}

provider "aws" {
  region = var.region
}

terraform {
  cloud {
    organization = "ntdtic"

    workspaces {
      name = "asg-delivery-test"
    }
  }
}