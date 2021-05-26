terraform {
  required_version = ">= 0.12.31, < 0.16"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.15"
    }
  }
}

provider "aws" {
  region = var.region
}

variable region {
  default = "us-east-1"
}
