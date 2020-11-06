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
  {
    name                          = "example-vmseries01-outside"
    source_dest_check             = false
    subnet_name                   = "example-public-1a"
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