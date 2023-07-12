<<<<<<<< HEAD:examples/centralized_design/versions.tf
terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25"
    }
    local = {
      version = "~> 2.4.0"
    }
  }
}

provider "aws" {
  region = var.region
}
========
terraform {
  required_version = ">= 1.0.0, < 2.0.0"
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
>>>>>>>> main:examples/isolated_design_autoscale/versions.tf
