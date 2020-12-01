terraform {
  required_version = ">=0.12.29, <0.14"
}

provider "aws" {
  # version = "~> 3"

  # Some bugs were fixed in 3.18
  version = "~> 3.18"

  region = var.region
}
