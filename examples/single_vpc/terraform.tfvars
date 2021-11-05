region = "us-east-1"

prefix_name_tag = "bar-" // Used for Name Tags of all created resources. Can be empty.

global_tags = {
  Foo         = "Bar"
  Environment = "dev"
  Team        = "SecOps"
  Managed-by  = "Terraform"
  Description = "VM-Series deployment in single VPC"
}

vpc_tags = {
  Description = "The VPC holding VM-Series"
}

vpc_cidr_block            = "10.100.0.0/16"
vpc_secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]

subnets = {
  "10.100.0.0/25"   = { az = "us-east-1a", set = "mgmt-1" }
  "10.100.0.128/25" = { az = "us-east-1b", set = "mgmt-1" }
  "10.100.1.0/25"   = { az = "us-east-1a", set = "public-1" }
  "10.100.1.128/25" = { az = "us-east-1b", set = "public-1" }
  "10.100.2.0/25"   = { az = "us-east-1a", set = "inside-1" }
  "10.100.2.128/25" = { az = "us-east-1b", set = "inside-1" }
  "10.100.3.0/25"   = { az = "us-east-1a", set = "natgw-1" }
  "10.100.3.128/25" = { az = "us-east-1b", set = "natgw-1" }
}

security_groups = {
  vmseries-mgmt = {
    name = "vmseries-mgmt"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https-inbound-private = {
        description = "Permit HTTPS for VM-Series Management"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
      https-inbound-eip = {
        description = "Permit HTTPS for VM-Series Management from known public IPs"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["100.100.100.100/32"]
      }
      ssh-inbound-eip = {
        description = "Permit SSH for VM-Series Management from known public IPs"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["100.100.100.100/32"]
      }
    }
  }
}

fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "9.1.3"

create_ssh_key           = true
ssh_key_name             = "vmseries_key"
ssh_public_key_file_path = "~/.ssh/id_rsa.pub"

interfaces = [
  {
    name                          = "vmseries01-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt-1a"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = true
  },
  {
    name                          = "vmseries01-outside"
    source_dest_check             = false
    subnet_name                   = "public-1a"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-inside"
    source_dest_check             = false
    subnet_name                   = "inside-1a"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt-1b"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = true
  },
  {
    name                          = "vmseries02-outside"
    source_dest_check             = false
    subnet_name                   = "public-1b"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-inside"
    source_dest_check             = false
    subnet_name                   = "inside-1b"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
  }
]


firewalls = [
  {
    name    = "vmseries01"
    fw_tags = { "foo" = "bar" }
    interfaces = [{ # Only assign default interface here to avoid instance recreation when later updating interfaces
      name  = "vmseries01-mgmt"
      index = "0"
    }]
    bootstrap_options = {}
  },
  {
    name    = "vmseries02"
    fw_tags = { "foo" = "bar" }
    interfaces = [{ # Only assign default interface here to avoid instance recreation when later updating interfaces
      name  = "vmseries02-mgmt"
      index = "0"
    }]
    bootstrap_options = {}
  }
]

addtional_interfaces = {
  vmseries01-outside = {
    ec2_instance = "vmseries01"
    index        = "1"
  },
  vmseries01-inside = {
    ec2_instance = "vmseries01"
    index        = "2"
  },
  vmseries02-outside = {
    ec2_instance = "vmseries02"
    index        = "1"
  },
  vmseries02-inside = {
    ec2_instance = "vmseries02"
    index        = "2"
  }
}
