region = "us-east-1"

shared_cred_profile = "default" # Named profile in aws credentials file

# Global tags that will be applied to all resources
tags = {
  Environment = "us-gov-east-1"
  Group       = "NetOps"
  Managed_By  = "Terraform"
  Description = "North/South Traffic"
}

# Prefix should match across all projects for the environment
prefix_name_tag = "my-example-"

# Import remote state from Base Infrastructure Terraform deployment
base_infra_state_bucket      = "palo-state-files"
base_infra_state_key         = "prod/base.tfstate"
base_infra_state_region      = "us-esast-1"
panorama_bootstrap_state_key = "prod/panorama.tfstate"


fw_instance_type = "m5.4xlarge"
fw_license_type  = "byol"
fw_version       = "9.1.0-h3"
ssh_key_name     = "my_ssh_key"

interfaces = [
  {
    name                          = "vmseries01-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt-1a"
    security_group                = "pan-mgmt"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-outside"
    source_dest_check             = false
    subnet_name                   = "vdss-outside-1a"
    security_group                = "pan-public"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-prod"
    source_dest_check             = false
    subnet_name                   = "inside-prod-1a"
    security_group                = "pan-tgw-prod"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-dev"
    source_dest_check             = false
    subnet_name                   = "inside-dev-1a"
    security_group                = "pan-tgw-dev"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-test"
    source_dest_check             = false
    subnet_name                   = "inside-test-1a"
    security_group                = "pan-tgw-test"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-tools"
    source_dest_check             = false
    subnet_name                   = "inside-tools-1a"
    security_group                = "pan-tgw-tools"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt-1b"
    security_group                = "pan-mgmt"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-outside"
    source_dest_check             = false
    subnet_name                   = "vdss-outside-1b"
    security_group                = "pan-public"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-prod"
    source_dest_check             = false
    subnet_name                   = "inside-prod-1b"
    security_group                = "pan-tgw-prod"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-dev"
    source_dest_check             = false
    subnet_name                   = "inside-dev-1b"
    security_group                = "pan-tgw-dev"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-test"
    source_dest_check             = false
    subnet_name                   = "inside-test-1b"
    security_group                = "pan-tgw-test"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-tools"
    source_dest_check             = false
    subnet_name                   = "inside-tools-1b"
    security_group                = "pan-tgw-tools"
    private_ip_address_allocation = "dynamic"
  }
]


firewalls = [{
  name                 = "vmseries01"
  fw_tags              = { "scheduler:ebs-snapshot" = "true" }
  iam_instance_profile = "pan-bootstrap-profile"
  bootstrap_bucket     = "goveast-vdss-az1a"
  bootstrap_options    = {}
  # bootstrap_options = {
  #   mgmt-interface-swap = "enable"
  #   aws-gwlb-inspect    = "enable"
  # }
  interfaces = [{ # Only assign default interface here to avoid instance recreation when later updating interfaces
    name  = "vmseries01-mgmt"
    index = "0"
  }]
  },
  {
    name                 = "vmseries02"
    fw_tags              = { "scheduler:ebs-snapshot" = "true" }
    iam_instance_profile = "pan-bootstrap-profile"
    bootstrap_bucket     = "goveast-vdss-az1b"
    bootstrap_options    = {}
    interfaces = [{ # Only assign default interface here to avoid instance recreation when later updating interfaces
      name  = "vmseries02-mgmt"
      index = "0"
    }]
  }
]

addtional_interfaces = {
  vmseries01-outside = {
    ec2_instance = "vmseries01"
    index        = "1"
  },
  vmseries01-prod = {
    ec2_instance = "vmseries01"
    index        = "2"
  },
  vmseries01-dev = {
    ec2_instance = "vmseries01"
    index        = "3"
  },
  vmseries01-test = {
    ec2_instance = "vmseries01"
    index        = "4"
  },
  vmseries01-tools = {
    ec2_instance = "vmseries01"
    index        = "5"
  },
  vmseries02-outside = {
    ec2_instance = "vmseries02"
    index        = "1"
  },
  vmseries02-prod = {
    ec2_instance = "vmseries02"
    index        = "2"
  },
  vmseries02-dev = {
    ec2_instance = "vmseries02"
    index        = "3"
  },
  vmseries02-tools = {
    ec2_instance = "vmseries02"
    index        = "4"
  },
  vmseries02-tools = {
    ec2_instance = "vmseries02"
    index        = "5"
  }
}

rts_to_fw_eni = {
  prod-tgw-default-to-fw = {
    route_table      = "tgw-prod-attach"
    eni              = "vmseries01-prod"
    destination_cidr = "0.0.0.0/0"
  }
  dev-tgw-default-to-fw = {
    route_table      = "tgw-dev-attach"
    eni              = "vmseries01-dev"
    destination_cidr = "0.0.0.0/0"
  }
  test-tgw-default-to-fw = {
    route_table      = "tgw-test-attach"
    eni              = "vmseries01-test"
    destination_cidr = "0.0.0.0/0"
  }
  tools-tgw-default-to-fw = {
    route_table      = "tgw-tools-attach"
    eni              = "vmseries01-tools"
    destination_cidr = "0.0.0.0/0"
  }
  vgw-ingress-prefix-1 = {
    route_table      = "vdss-goveast"
    eni              = "vmseries01-outside"
    destination_cidr = "10.100.0.0/24"
  }
}