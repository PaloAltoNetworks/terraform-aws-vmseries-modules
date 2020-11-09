terraform {
  required_version = ">=0.12.29, <0.14"
  required_providers {
    aws = {
      version = "~> 3.10"
    }
  }
}

provider "aws" {
  region  = var.region
}