region = "us-east-1"

prefix_name_tag = "bar-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  foo         = "bar"
  managed-by  = "Terraform"
  description = "VM-Series deployment in single VPC"
}

vpc = { // Module only designed for a single VPC. Set all params here. If existing = true, specify the Name tag of existing VPC
  vmseries-vpc = {
    existing              = false
    name                  = "bar"
    cidr_block            = "10.100.0.0/16"
    secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]
    instance_tenancy      = "default"
    enable_dns_support    = true
    enable_dns_hostnames  = true
    internet_gateway      = true
    local_tags            = { "foo" = "bar" }
  }
}

vpc_route_tables = {
  mgmt       = { name = "mgmt" }
  public     = { name = "public" }
  tgw-return = { name = "tgw-return" }
  tgw-attach = { name = "tgw-attach" }
  lambda     = { name = "lambda" }
}

subnets = {
  # mgmt-1a       = { existing = true, name = "mgmt-1a" } // For brownfield, set existing = true with name tag of existing subnet
  mgmt-1a       = { name = "mgmt-1a", cidr = "10.100.0.0/25", az = "us-east-1a", rt = "mgmt", local_tags = { "foo" = "bar" } }
  public-1a     = { name = "public-1a", cidr = "10.100.1.0/25", az = "us-east-1a", rt = "public" }
  inside-1a     = { name = "inside-1a", cidr = "10.100.2.0/25", az = "us-east-1a", rt = "tgw-return" }
  tgw-attach-1a = { name = "tgw-attach-1a", cidr = "10.100.3.0/25", az = "us-east-1a", rt = "tgw-attach" }
  lambda-1a     = { name = "lambda-1a", cidr = "10.100.4.0/25", az = "us-east-1a", rt = "lambda" }

  mgmt-1b       = { name = "mgmt-1b", cidr = "10.100.0.128/25", az = "us-east-1b", rt = "mgmt" }
  public-1b     = { name = "public-1b", cidr = "10.100.1.128/25", az = "us-east-1b", rt = "public" }
  inside-1b     = { name = "inside-1b", cidr = "10.100.2.128/25", az = "us-east-1b", rt = "tgw-return" }
  tgw-attach-1b = { name = "tgw-attach-1b", cidr = "10.100.3.128/25", az = "us-east-1b", rt = "tgw-attach" }
  lambda-1b     = { name = "lambda-1b", cidr = "10.100.4.128/25", az = "us-east-1b", rt = "lambda" }
}

nat_gateways = {
  public-1a = { name = "public-1a-natgw", subnet = "public-1a", local_tags = { "foo" = "bar" } }
  public-1b = { name = "public-1b-natgw", subnet = "public-1a" }
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

vpc_routes = {
  mgmt-igw = {
    route_table   = "mgmt"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
  public-igw = {
    route_table   = "public"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
}


fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "9.1.3"
ssh_key_name     = "bar"

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


firewalls = [{
  name    = "vmseries01"
  fw_tags = { "foo" = "bar" }
  interfaces = [{ # Only assign default interface here to avoid instance recreation when later updating interfaces
    name  = "vmseries01-mgmt"
    index = "0"
  }]
  },
  {
    name    = "vmseries02"
    fw_tags = { "foo" = "bar" }
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