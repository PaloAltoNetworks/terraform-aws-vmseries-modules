### GENERAL SETTING
region           = "us-east-1"
prefix_name_tag  = "kbechler-"
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.2"
ssh_key_name     = "kbechler4k"
global_tags = {
  managed-by = "Terraform"
}



### VPC
vpcs = {
  vmseries-vpc = {
    name                 = "some-vpc"
    cidr_block           = "172.21.0.0/16"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    internet_gateway     = true
  }
}


route_tables = {
  mgmt1 = { name = "mgmt1" }
  data1 = { name = "data1" }
}


vpc_subnets = {
  mgmt1 = { name = "mgmt1", cidr = "172.21.0.0/24", az = "us-east-1b", rt = "mgmt1", local_tags = { "vmseries" = "nic1" } }
  data1 = { name = "data1", cidr = "172.21.1.0/24", az = "us-east-1b", rt = "data1" }
  mgmt2 = { name = "mgmt2", cidr = "172.21.10.0/24", az = "us-east-1c", rt = "mgmt1", local_tags = { "vmseries" = "nic1" } }
  data2 = { name = "data2", cidr = "172.21.11.0/24", az = "us-east-1c", rt = "data1" }
}


security_groups = {
  vmseries-data = {
    name = "vmseries-data"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  },
  vmseries-mgmt = {
    name = "vmseries-mgmt"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      mgmt_ssh = {
        description = "Permit SSH from Trusted"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["1.2.3.4/32"]
      }
      mgmt_https = {
        description = "Permit HTTPS from Trusted"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["1.2.3.4/32"]
      }

    }
  }
}



### ASG
bootstrap_options = {
  panorama-server   = "1.2.3.4",
  panorama-server-2 = "3.4.5.6"
  tplname           = "some-tpl"
  dgname            = "some-dg"
  dns-primary       = "8.8.8.8"
  dns-secondary     = "8.8.4.4"
  vm-auth-key       = ""
  op-command-modes  = "mgmt-interface-swap=enable"
}



interfaces = [
  {
    index          = "0"
    security_group = "vmseries-data"
  },
  {
    index          = "1"
    security_group = "vmseries-mgmt"
  },
]

nic0_subnets = [ "data1", "data2" ]


### GWLB
gateway_load_balancers = {
  security-gwlb = {
    name           = "security-gwlb"
    subnet_names   = ["data1"]
    firewall_names = [] # this must be ampty for using GWLB module with ASG
    asg_name       = null
    # asg_name       = "asg1" # "asg1" is the default value of asg_name in asg module
  }
}


gateway_load_balancer_subnets = ["data1"]


gateway_load_balancer_endpoints = {
  east-west1 = {
    name                  = "east-west-gwlb-endpoint1"
    gateway_load_balancer = "security-gwlb"
    subnet_names          = ["data1"]
  }
  # east-west2 = {
  #   name                  = "east-west-gwlb-endpoint2"
  #   gateway_load_balancer = "security-gwlb"
  #   subnet_names          = ["gwlbe-eastwest-2"]
  # }
  # outbound1 = {
  #   name                  = "outbound-gwlb-endpoint1"
  #   gateway_load_balancer = "security-gwlb"
  #   subnet_names          = ["gwlbe-outbound-1"]
  # }
  # outbound2 = {
  #   name                  = "outbound-gwlb-endpoint2"
  #   gateway_load_balancer = "security-gwlb"
  #   subnet_names          = ["gwlbe-outbound-2"]
  # }
}
