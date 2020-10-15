terraform {
  required_version = "~> 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}

provider "aws" {
  region  = var.region
  version = "3.8.0"
  profile = "default"
}


module "vpc_all_options" {
  source                          = "../../modules/vpc"
  global_tags                     = var.global_tags
  prefix_name_tag                 = var.prefix_name_tag
  vpc                             = var.vpc
  subnets                         = var.subnets
}

