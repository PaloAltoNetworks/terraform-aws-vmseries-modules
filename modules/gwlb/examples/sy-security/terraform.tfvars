### Global
region           = "eu-west-1"
prefix_name_tag  = "syoungberg-gwlb1-"
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.2"
ssh_key_name     = "seany-ca-central"
global_tags = {
  managed-by = "Terraform"
}

### VPC ###
north-south_vpc = {
  vmseries-vpc = {
    name                 = "outbound"
    cidr_block           = "10.208.4.0/23"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    internet_gateway     = true

  }
}

north-south_vpc_route_tables = {
  mgmt1            = { name = "mgmt1" }
  mgmt2            = { name = "mgmt2" }
  data1            = { name = "data1" }
  data2            = { name = "data2" }
  gwlbe-eastwest-1 = { name = "gwlbe-eastwest-1" }
  gwlbe-eastwest-2 = { name = "gwlbe-eastwest-2" }
  gwlbe-outbound-1 = { name = "gwlbe-outbound-1" }
  gwlbe-outbound-2 = { name = "gwlbe-outbound-2" }
  tgw-attach1      = { name = "tgw-attach1" }
  tgw-attach2      = { name = "tgw-attach2" }
  natgw1           = { name = "natgw1" }
  natgw2           = { name = "natgw2" }

}

north-south_vpc_subnets = {
  mgmt1            = { name = "mgmt1", cidr = "10.208.4.0/28", az = "eu-west-1b", rt = "mgmt1" }
  mgmt2            = { name = "mgmt2", cidr = "10.208.5.0/28", az = "eu-west-1c", rt = "mgmt2" }
  data1            = { name = "data1", cidr = "10.208.4.16/28", az = "eu-west-1b", rt = "data1" }
  data2            = { name = "data2", cidr = "10.208.5.16/28", az = "eu-west-1c", rt = "data2" }
  gwlbe-eastwest-1 = { name = "gwlbe-eastwest-1", cidr = "10.208.4.32/28", az = "eu-west-1b", rt = "gwlbe-eastwest-1" }
  gwlbe-eastwest-2 = { name = "gwlbe-eastwest-2", cidr = "10.208.5.32/28", az = "eu-west-1c", rt = "gwlbe-eastwest-2" }
  gwlbe-outbound-1 = { name = "gwlbe-outbound-1", cidr = "10.208.4.48/28", az = "eu-west-1b", rt = "gwlbe-outbound-1" }
  gwlbe-outbound-2 = { name = "gwlbe-outbound-2", cidr = "10.208.5.48/28", az = "eu-west-1c", rt = "gwlbe-outbound-2" }
  tgw-attach1      = { name = "tgw-attach1", cidr = "10.208.4.64/28", az = "eu-west-1b", rt = "tgw-attach1" }
  tgw-attach2      = { name = "tgw-attach2", cidr = "10.208.5.64/28", az = "eu-west-1c", rt = "tgw-attach2" }
  natgw1           = { name = "natgw1", cidr = "10.208.4.80/28", az = "eu-west-1b", rt = "natgw1" }
  natgw2           = { name = "natgw2", cidr = "10.208.5.80/28", az = "eu-west-1c", rt = "natgw2" }
}

north-south_nat_gateways = {
  natgw1 = { name = "public-1-natgw", subnet = "natgw1" }
  natgw2 = { name = "public-2-natgw", subnet = "natgw2" }
}

north-south_vpc_endpoints = {
}

north-south_vpc_security_groups = {
  vmseries-data = {
    name = "vmseries-data"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      geneve = {
        description = "Permit GENEVE"
        type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
        cidr_blocks = ["10.208.0.0/16"]
      }
      health_probe = {
        description = "Permit Port 80 GWLB Health Probe"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["10.208.0.0/16"]
      }

    }
  }

  gwlbe = {
    name = "gwlbe"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh1 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["34.99.115.242/32"]
      }
      ssh2 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["10.208.0.0/16"]
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
        cidr_blocks = ["34.99.115.242/32"]
      }
      ssh2 = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["10.208.0.0/16"]
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["34.99.115.242/32"]
      }
    }
  }

}


### GWLB ###
gwlb_subnets = ["gwlbe-eastwest-1", "gwlbe-eastwest-2"]

gateway_load_balancers = {
  security-gwlb = {
    name = "security-gwlb"
    subnet_names          = ["data1", "data2"]
    #allowed_principals = []
  }
}

gateway_load_balancer_endpoints = {
  east-west1 = {
    name                  = "east-west-gwlb-endpoint1"
    gateway_load_balancer = "security-gwlb"
    subnet_names          = ["gwlbe-eastwest-1"]
  }
  east-west2 = {
    name                  = "east-west-gwlb-endpoint2"
    gateway_load_balancer = "security-gwlb"
    subnet_names          = ["gwlbe-eastwest-2"]
  }
  outbound1 = {
    name                  = "outbound-gwlb-endpoint1"
    gateway_load_balancer = "security-gwlb"
    subnet_names          = ["gwlbe-outbound-1"]
  }
  outbound2 = {
    name                  = "outbound-gwlb-endpoint2"
    gateway_load_balancer = "security-gwlb"
    subnet_names          = ["gwlbe-outbound-2"]
  }
}

### VMSERIES ###
north-south_firewalls = [
  {
    name                = "syoungberg-vmseries01"
    fw_tags             = {}
    mgmt-interface-swap = "enable"
    aws-gwlb-inspect    = "enable"
    # bootstrap_bucket     = "vmseries01"
    # iam_instance_profile = "pan-bootstrap-ns-profile"
    interfaces = [
      { name = "vmseries01-data", index = "0" },
      { name = "vmseries01-mgmt", index = "1" },
    ]
  },
  {
    name                = "syoungberg-vmseries02"
    fw_tags             = {}
    mgmt-interface-swap = "enable"
    aws-gwlb-inspect    = "enable"
    # bootstrap_bucket     = "vmseries02"
    # iam_instance_profile = "pan-bootstrap-ns-profile"
    interfaces = [
      { name = "vmseries02-data", index = "0" },
      { name = "vmseries02-mgmt", index = "1" },
    ]
  }
]

north-south_interfaces = [
  ## first firewall
  {
    name                          = "vmseries01-data"
    source_dest_check             = false
    subnet_name                   = "data1"
    security_group                = "vmseries-data"
    private_ip_address_allocation = "dynamic"
    #eip                           = false
  },
  {
    name                          = "vmseries01-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt1"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries01-mgmt"
  },

  # second firewall
  {
    name                          = "vmseries02-data"
    source_dest_check             = false
    subnet_name                   = "data2"
    security_group                = "vmseries-data"
    private_ip_address_allocation = "dynamic"
    #eip                           = false
  },
  {
    name                          = "vmseries02-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt2"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries02-mgmt"
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
  #   next_hop_name = "gwlb-1a-natgw"
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
  mgmt1-igw = {
    route_table   = "mgmt1"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
  mgmt2-igw = {
    route_table   = "mgmt2"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
  natgw1-igw = {
    route_table   = "natgw1"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
  natgw2-igw = {
    route_table   = "natgw2"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vmseries-vpc"
  }
  gwlbe1-to-natgw1 = {
    route_table   = "gwlbe-outbound-1"
    prefix        = "0.0.0.0/0"
    next_hop_type = "nat_gateway"
    next_hop_name = "natgw1"
  }
  gwlbe1-to-natgw1 = {
    route_table   = "gwlbe-outbound-2"
    prefix        = "0.0.0.0/0"
    next_hop_type = "nat_gateway"
    next_hop_name = "natgw2"
  }
}
