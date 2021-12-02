region           = "us-east-1"
prefix_name_tag  = "example-"
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.7" # Can be empty.

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series Combined"
  Owner       = "PS team"
  Creator     = "login"
}

transit_gateway_name = "tgw"
transit_gateway_asn  = "65200"
transit_gateway_route_tables = {
  "from_security_vpc" = {
    create = true
    name   = "from_security"
  }
  "from_spoke_vpc" = {
    create = true
    name   = "from_spokes"
  }
}

### Security VPC ###

security_transit_gateway_attachment_name = "security-vpc-attach"

security_vpc_name = "security-vpc"
security_vpc_cidr = "10.100.0.0/16"

nat_gateway_name = "natgw"

gwlb_name                       = "security-gwlb"
gwlb_endpoint_set_eastwest_name = "eastwest-gwlb-endpoint"
gwlb_endpoint_set_outbound_name = "outbound-gwlb-endpoint"

security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"   = { az = "us-east-1a", set = "mgmt" }
  "10.100.64.0/24"  = { az = "us-east-1b", set = "mgmt" }
  "10.100.1.0/24"   = { az = "us-east-1a", set = "data1" }
  "10.100.65.0/24"  = { az = "us-east-1b", set = "data1" }
  "10.100.3.0/24"   = { az = "us-east-1a", set = "tgw_attach" }
  "10.100.67.0/24"  = { az = "us-east-1b", set = "tgw_attach" }
  "10.100.4.0/24"   = { az = "us-east-1a", set = "gwlbe_outbound" }
  "10.100.68.0/24"  = { az = "us-east-1b", set = "gwlbe_outbound" }
  "10.100.5.0/24"   = { az = "us-east-1a", set = "gwlb" }
  "10.100.69.0/24"  = { az = "us-east-1b", set = "gwlb" }
  "10.100.132.0/24" = { az = "us-east-1c", set = "gwlb" }
  "10.100.201.0/24" = { az = "us-east-1d", set = "gwlb" }
  "10.100.6.0/24"   = { az = "us-east-1e", set = "gwlb" }
  "10.100.70.0/24"  = { az = "us-east-1f", set = "gwlb" } # AWS reccomends to always go up to the last possible AZ for GWLB service.
  "10.100.10.0/24"  = { az = "us-east-1a", set = "gwlbe_eastwest" }
  "10.100.74.0/24"  = { az = "us-east-1b", set = "gwlbe_eastwest" }
  "10.100.11.0/24"  = { az = "us-east-1a", set = "natgw" }
  "10.100.75.0/24"  = { az = "us-east-1b", set = "natgw" }
}

security_vpc_security_groups = {
  vmseries_data = {
    name = "vmseries_data"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      geneve = {
        description = "Permit GENEVE to GWLB subnets"
        type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
        cidr_blocks = ["10.100.5.0/24", "10.100.69.0/24", "10.100.132.0/24", "10.100.201.0/24", "10.100.6.0/24", "10.100.70.0/24"]
      }
      health_probe = {
        description = "Permit Port 80 Health Probe to GWLB subnets"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["10.100.5.0/24", "10.100.69.0/24", "10.100.132.0/24", "10.100.201.0/24", "10.100.6.0/24", "10.100.70.0/24"]
      }
    }
  }
  vmseries_mgmt = {
    name = "vmseries_mgmt"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      panorama_ssh = {
        description = "Permit Panorama SSH (Optional)"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
      panorama_mgmt = {
        description = "Permit Panorama Management"
        type        = "ingress", from_port = "3978", to_port = "3978", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
      panorama_log = {
        description = "Permit Panorama Logging"
        type        = "ingress", from_port = "28443", to_port = "28443", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
    }
  }
}

### Security VPC routes ###

security_vpc_routes_outbound_source_cidrs = [ # outbound traffic return after inspection
  "10.0.0.0/8",
]

security_vpc_routes_outbound_destin_cidrs = [ # outbound traffic incoming for inspection from TGW
  "0.0.0.0/0",
]

security_vpc_routes_eastwest_cidrs = [ # eastwest traffic incoming for inspection from TGW
  "10.0.0.0/8",
]

security_vpc_mgmt_routes_to_tgw = [
  "10.255.0.0/16", # Panorama via TGW (must not repeat any security_vpc_routes_eastwest_cidrs)
]

### EC2 VM-Series ###

firewalls = [
  {
    name    = "vmseries01"
    fw_tags = {}
    # The bootstrap_options are ignored, because main.tf uses vmseries-bootstrap-aws-s3bucket = module.bootstrap.bucket_name
    # bootstrap_options = {
    #   mgmt-interface-swap = "enable"
    #   plugin-op-commands  = "aws-gwlb-inspect:enable"
    #   type                = "dhcp-client"
    #   hostname            = "vmseries01"
    #   tplname             = "TPL-MY-STACK-##"
    #   dgname              = "DG-MY-##"
    #   panorama-server     = "xxx"
    #   panorama-server-2   = "xxx"
    #   vm-auth-key         = "xxx"
    #   authcodes           = "xxx"
    #   op-command-modes    = ""
    # }
    interfaces = [
      { name = "vmseries01_data", index = "0" },
      { name = "vmseries01_mgmt", index = "1" },
    ]
  },
  {
    name    = "vmseries02"
    fw_tags = {}
    # The bootstrap_options are ignored, because main.tf uses vmseries-bootstrap-aws-s3bucket = module.bootstrap.bucket_name
    # bootstrap_options = {
    #   mgmt-interface-swap = "enable"
    #   plugin-op-commands  = "aws-gwlb-inspect:enable"
    #   type                = "dhcp-client"
    #   hostname            = "vmseries02"
    #   tplname             = "TPL-MY-STACK-##"
    #   dgname              = "DG-MY-##"
    #   panorama-server     = "xxx"
    #   panorama-server-2   = "xxx"
    #   vm-auth-key         = "xxx"
    #   authcodes           = "xxx"
    #   op-command-modes    = ""
    # }
    interfaces = [
      { name = "vmseries02_data", index = "0" },
      { name = "vmseries02_mgmt", index = "1" },
    ]
  }
]

interfaces = [
  # vmseries01
  {
    name                          = "vmseries01_data"
    source_dest_check             = false
    subnet_name                   = "data1a"
    security_group                = "vmseries_data"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01_mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmta"
    security_group                = "vmseries_mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries01_mgmt" # for the module's old version
    eip_name                      = "vmseries01_mgmt"
  },
  # vmseries02
  {
    name                          = "vmseries02_data"
    source_dest_check             = false
    subnet_name                   = "data1b"
    security_group                = "vmseries_data"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02_mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmtb"
    security_group                = "vmseries_mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries02_mgmt" # for the module's old version
    eip_name                      = "vmseries02_mgmt"
  },
]

### EC2 SSH Key ###

create_ssh_key      = true
ssh_key_name        = "vmseries_key"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

### App1 VPC ###

app1_transit_gateway_attachment_name = "app1-spoke-vpc"

app1_vpc_name = "app1-spoke-vpc"
app1_vpc_cidr = "10.104.0.0/16"

# Pull back info from existing GWLB in security VPC.
existing_gwlb_name          = "security-gwlb"
app1_gwlb_endpoint_set_name = "app1-gwlb-endpoint"

app1_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.104.0.0/24"   = { az = "us-east-1a", set = "app1_vm" }
  "10.104.128.0/24" = { az = "us-east-1b", set = "app1_vm" }
  "10.104.2.0/24"   = { az = "us-east-1a", set = "app1_lb" }
  "10.104.130.0/24" = { az = "us-east-1b", set = "app1_lb" }
  "10.104.3.0/24"   = { az = "us-east-1a", set = "app1_gwlbe" }
  "10.104.131.0/24" = { az = "us-east-1b", set = "app1_gwlbe" }
}

app1_vpc_security_groups = {
  app1_vm = {
    name = "app1_vm"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      http = {
        description = "Permit HTTP"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
    }
  }
}
