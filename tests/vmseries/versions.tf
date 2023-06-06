terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.3.2, <= 3.4.3"
    }
  }
}

provider "aws" {
  region = var.region
}
