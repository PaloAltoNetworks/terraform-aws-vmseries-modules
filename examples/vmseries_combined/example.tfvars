region           = "eu-west-2"
prefix_name_tag  = "example-"
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.4" # Can be empty.

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series Combined"
  Owner       = "PS team"
  Creator     = "login"
}

security_vpc_name = "security1"
security_vpc_cidr = "10.100.0.0/16"

nat_gateway_name = "natgw"

gwlb_name                       = "security-gwlb"
gwlb_endpoint_set_eastwest_name = "eastwest-gwlb-endpoint"
gwlb_endpoint_set_outbound_name = "outbound-gwlb-endpoint"

transit_gateway_name                = "tgw"
transit_gateway_asn                 = "65200"
security_transit_gateway_attachment = "security-vpc"

security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"  = { az = "eu-west-2a", set = "mgmt" }
  "10.100.64.0/24" = { az = "eu-west-2b", set = "mgmt" }
  "10.100.1.0/24"  = { az = "eu-west-2a", set = "data1" }
  "10.100.65.0/24" = { az = "eu-west-2b", set = "data1" }
  "10.100.5.0/24"  = { az = "eu-west-2a", set = "gwlb" }
  "10.100.69.0/24" = { az = "eu-west-2b", set = "gwlb" }
  "10.100.3.0/24"  = { az = "eu-west-2a", set = "tgw_attach" }
  "10.100.67.0/24" = { az = "eu-west-2b", set = "tgw_attach" }
  "10.100.4.0/24"  = { az = "eu-west-2a", set = "gwlbe_outbound" }
  "10.100.68.0/24" = { az = "eu-west-2b", set = "gwlbe_outbound" }
  "10.100.10.0/24" = { az = "eu-west-2a", set = "gwlbe_eastwest" }
  "10.100.74.0/24" = { az = "eu-west-2b", set = "gwlbe_eastwest" }
  "10.100.11.0/24" = { az = "eu-west-2a", set = "natgw" } # TODO: check if all the cidrs match the Ref-Arch addressing
  "10.100.75.0/24" = { az = "eu-west-2b", set = "natgw" }
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
        description = "Permit GENEVE"
        type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
        cidr_blocks = ["10.100.5.0/24", "10.100.69.0/24"]
      }
      health_probe = {
        description = "Permit Port 80 GWLB Health Probe"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["10.100.5.0/24", "10.100.69.0/24"]
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
      testbox = {
        description = "Permit SSH from App1 spoke VPC - optional test"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["10.104.0.0/23"]
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

### VMSERIES ###

firewalls = [
  {
    name    = "vmseries01"
    fw_tags = {}
    bootstrap_options = {
      mgmt-interface-swap = "enable"
      plugin-op-commands  = "aws-gwlb-inspect:enable"
      type                = "dhcp-client"
      hostname            = "vmseries01"
      tplname             = "TPL-MY-STACK-##"
      dgname              = "DG-MY-##"
      panorama-server     = "xxx"
      panorama-server-2   = "xxx"
      vm-auth-key         = "xxx"
      authcodes           = "xxx"
      op-command-modes    = ""
    }
    interfaces = [
      { name = "vmseries01_data", index = "0" },
      { name = "vmseries01_mgmt", index = "1" },
    ]
  },
  {
    name    = "vmseries02"
    fw_tags = {}
    bootstrap_options = {
      mgmt-interface-swap = "enable"
      plugin-op-commands  = "aws-gwlb-inspect:enable"
      type                = "dhcp-client"
      hostname            = "vmseries02"
      tplname             = "TPL-MY-STACK-##"
      dgname              = "DG-MY-##"
      panorama-server     = "xxx"
      panorama-server-2   = "xxx"
      vm-auth-key         = "xxx"
      authcodes           = "xxx"
      op-command-modes    = ""
    }
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

create_ssh_key           = true
ssh_key_name             = "vmseries_key_pair"
ssh_public_key_file_path = "~/.ssh/id_rsa.pub"

### Security VPC ROUTES ###

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

### Application1 VPC ###

app1_vpc_name = "app1-spoke-vpc"
app1_vpc_cidr = "10.104.0.0/23"

app1_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.104.0.16/28" = { az = "eu-west-2a", set = "app1_alb" }
  "10.104.1.16/28" = { az = "eu-west-2b", set = "app1_alb" }
  "10.104.0.32/28" = { az = "eu-west-2a", set = "app1_gwlbe" }
  "10.104.1.32/28" = { az = "eu-west-2b", set = "app1_gwlbe" }
  "10.104.0.48/28" = { az = "eu-west-2a", set = "app1_web" }
  "10.104.1.48/28" = { az = "eu-west-2b", set = "app1_web" }
}

# TODO: check if all the cidrs match the Ref-Arch addressing

app1_vpc_security_groups = {
  app1_web = {
    name = "app1_web"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8", "84.207.227.0/28"] # TODO: update here
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8", "84.207.227.0/28"] # TODO: update here
      }
      http = {
        description = "Permit HTTP"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8", "84.207.227.0/28"] # TODO: update here
      }
    }
  }
}

### Application1 GWLB ###

# Pull back info from existing GWLB endpoint service in security VPC
existing_gwlb_name                   = "security-gwlb"
gwlb_endpoint_set_app1_name          = "app1-gwlb-endpoint"
app1_transit_gateway_attachment_name = "app1-vpc"
