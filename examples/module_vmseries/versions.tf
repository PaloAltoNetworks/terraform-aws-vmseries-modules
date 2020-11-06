terraform {
  required_version = ">=0.12.29, <0.14"
}

provider "aws" {
  version = "~> 3"
  region  = var.region
}
