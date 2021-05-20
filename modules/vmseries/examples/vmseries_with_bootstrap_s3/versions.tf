terraform {
  required_version = ">=0.13, <0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=3.20"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}
