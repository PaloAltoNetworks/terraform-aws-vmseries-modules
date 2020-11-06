# VM-Series module

## Overview
Module for deploying Palo Alto Networks VM-Series firewalls. 

### Example
`main.tf`
```
module "vmseries" {
  source              = "../../modules/vmseries"
  region              = var.region
  tags                = var.tags
  ssh_key_name        = var.ssh_key_name
  interfaces          = var.interfaces
  firewalls           = var.firewalls
  prefix_name_tag     = var.prefix_name_tag
  security_groups_map = var.security_groups_map
  subnets_map         = var.subnets_map
}
```

`terraform.tfvars`
```
region          = "us-east-1"
prefix_name_tag = "example-"
ssh_key_name    = "example-ssh-key"
security_groups = "example-sg"

tags = {
  foo        = "bar"
  Managed_By = "Terraform"
}

security_groups_map = {
  "default" : "sg-00b7d744ffdf39e6a"
}

subnets_map = {
  "example-mgmt-1a"   = "subnet-0588b9eae3ee06d76"
  "example-public-1a" = "subnet-065b7b1e079413a02"
}

interfaces = [
  {
    name                          = "example-vmseries01-mgmt"
    source_dest_check             = true
    subnet_name                   = "example-mgmt-1a"
    security_group                = "default"
    private_ip_address_allocation = "dynamic"
  },
]

firewalls = [{
  name    = "example-vmseries01"
  fw_tags = { "scheduler:ebs-snapshot" = "true" }
  interfaces = [{
    name  = "example-vmseries01-mgmt"
    index = "0"
  }]
  }
]
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=0.12.29, <0.14 |
| aws | ~> 3 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3 |

## Inputs

## Outputs

## Nested Map Input Variable Definitions

For each of the nested map variables, the key of each map will be the terraform state resource identifier within terraform and must be unique, but is not used for resource naming.

