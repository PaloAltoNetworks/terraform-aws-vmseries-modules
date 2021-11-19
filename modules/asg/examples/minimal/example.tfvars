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
  mgmt1 = { name = "mgmt1", cidr = "172.21.0.0/24", az = "us-east-1b", rt = "mgmt1" }
  data1 = { name = "data1", cidr = "172.21.1.0/24", az = "us-east-1b", rt = "data1" }
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
    subnet_name    = "data1"
    security_group = "vmseries-data"
  },
  {
    index          = "1"
    subnet_name    = "mgmt1"
    security_group = "vmseries-mgmt"
  },
]
