### Global
region           = "us-east-1"
prefix_name_tag  = "kbechler-gwlb2-"
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.2"
ssh_key_name     = "kbechler4k"
global_tags = {
  managed-by = "Terraform"
}

### VPC ###
north-south_vpc = {
  vmseries-vpc = {
    name                 = "outbound"
    cidr_block           = "172.18.0.0/16"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    internet_gateway     = true

  }
}

north-south_vpc_route_tables = {
  trust  = { name = "trust" }
  public = { name = "public" }
  mgmt   = { name = "mgmt" }
}

north-south_vpc_subnets = {
  trust1  = { name = "trust1", cidr = "172.18.1.0/24", az = "us-east-1b", rt = "trust" }
  trust2  = { name = "trust2", cidr = "172.18.2.0/24", az = "us-east-1c", rt = "trust" }
  public1 = { name = "public1", cidr = "172.18.3.0/24", az = "us-east-1b", rt = "public" }
  public2 = { name = "public2", cidr = "172.18.4.0/24", az = "us-east-1c", rt = "public" }
  mgmt1   = { name = "mgmt1", cidr = "172.18.7.0/24", az = "us-east-1b", rt = "mgmt" }
  mgmt2   = { name = "mgmt2", cidr = "172.18.8.0/24", az = "us-east-1c", rt = "mgmt" }
}

north-south_nat_gateways = {
  # public-1a = { name = "public-1a-natgw", subnet = "public-1a" }
}

north-south_vpc_endpoints = {
}

north-south_vpc_security_groups = {
  vmseries-trust = {
    name = "vmseries-trust"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh1 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["5.173.0.0/16"]
      }
      l172 = {
        description = "Permit 172.18.0.0/16"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["172.18.0.0/16"]
      }

    }
  }

  vmseries-public = {
    name = "vmseries-public"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh1 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["5.173.0.0/16"]
      }
      ssh2 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["172.18.0.0/16"]
      }
    }
  }

  vmseries-mgmt = {
    name = "vmseries-mgmt"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh1 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["5.173.0.0/16"]
      }
      ssh2 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["172.18.0.0/16"]
      }
    }
  }

}


### GWLB ###
gwlb_subnets = ["trust1", "trust2"]




### VMSERIES ###
north-south_firewalls = [
  {
    name                = "kbechler-vmseries01"
    fw_tags             = {}
    mgmt-interface-swap = "enable"
    # bootstrap_bucket     = "vmseries01"
    # iam_instance_profile = "pan-bootstrap-ns-profile"
    interfaces = [
      { name = "vmseries01-public", index = "0" },
      { name = "vmseries01-mgmt", index = "1" },
      { name = "vmseries01-trust", index = "2" },
    ]
  },
  {
    name                = "kbechler-vmseries02"
    fw_tags             = {}
    mgmt-interface-swap = "enable"
    # bootstrap_bucket     = "vmseries02"
    # iam_instance_profile = "pan-bootstrap-ns-profile"
    interfaces = [
      { name = "vmseries02-public", index = "0" },
      { name = "vmseries02-mgmt", index = "1" },
      { name = "vmseries02-trust", index = "2" },
    ]
  }
]

north-south_interfaces = [
  ## first firewall
  {
    name                          = "vmseries01-trust"
    source_dest_check             = false
    subnet_name                   = "trust1"
    security_group                = "vmseries-trust"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-public"
    source_dest_check             = false
    subnet_name                   = "public1"
    security_group                = "vmseries-public"
    private_ip_address_allocation = "dynamic"
    eip                           = true
  },
  {
    name                          = "vmseries01-mgmt"
    source_dest_check             = false
    subnet_name                   = "mgmt1"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = true
  },

  # second firewall
  {
    name                          = "vmseries02-trust"
    source_dest_check             = false
    subnet_name                   = "trust2"
    security_group                = "vmseries-trust"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-public"
    source_dest_check             = false
    subnet_name                   = "public2"
    security_group                = "vmseries-public"
    private_ip_address_allocation = "dynamic"
    eip                           = true
  },
  {
    name                          = "vmseries02-mgmt"
    source_dest_check             = false
    subnet_name                   = "mgmt2"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = true
  },
]

north-south_addtional_interfaces = {
}

### VPC_ROUTES
north-south_vpc_routes = {
  # mgmt-igw = {
  #   route_table   = "mgmt"
  #   prefix        = "0.0.0.0/0"
  #   next_hop_type = "nat_gateway"
  #   next_hop_name = "public-1a-natgw"
  # }
  # mgmt-tgw       = { 
  #   route_table = "mgmt"
  #   prefix = "10.0.0.0/8"
  #   next_hop_type = "transit_gateway"
  #   next_hop_name = "my-tgw"
  # }
  # mgmt-vgw = {
  #   route_table   = "mgmt"
  #   prefix        = "172.16.0.0/12"
  #   next_hop_type = "vpn_gateway"
  #   next_hop_name = "vmseries_vgw"
  # }
  # mgmt-igw = {
  #   route_table   = "mgmt"
  #   prefix        = "0.0.0.0/0"
  #   next_hop_type = "internet_gateway"
  #   next_hop_name = "vmseries-vpc"
  # }
  public-igw = {
    route_table   = "public"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
  mgmt-igw = {
    route_table   = "mgmt"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
}



