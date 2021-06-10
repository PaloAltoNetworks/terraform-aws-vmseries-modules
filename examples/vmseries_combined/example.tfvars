region           = "eu-west-2"
prefix_name_tag  = "example-"
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.4" # Can be empty.

global_tags = {
  managedBy   = "terraform"
  application = "Palo Alto Networks VM-Series Combined"
  owner       = "PS team"
}

security_vpc_name = "security"
security_vpc_cidr = "10.100.0.0/16"

security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"  = { az = "eu-west-2a", set = "mgmt" }
  "10.100.64.0/24" = { az = "eu-west-2b", set = "mgmt" }
  "10.100.1.0/24"  = { az = "eu-west-2a", set = "data" } # TODO: have a dedicated gwlb subnet 10.100.5.0
  "10.100.65.0/24" = { az = "eu-west-2b", set = "data" }
  "10.100.3.0/24"  = { az = "eu-west-2a", set = "tgw-attach" }
  "10.100.67.0/24" = { az = "eu-west-2b", set = "tgw-attach" }
  "10.100.4.0/24"  = { az = "eu-west-2a", set = "gwlbe-outbound" }
  "10.100.68.0/24" = { az = "eu-west-2b", set = "gwlbe-outbound" }
  "10.100.10.0/24" = { az = "eu-west-2a", set = "gwlbe-eastwest" }
  "10.100.74.0/24" = { az = "eu-west-2b", set = "gwlbe-eastwest" }
  "10.100.11.0/24" = { az = "eu-west-2a", set = "natgw" } # TODO: check if all the cidrs match the Ref-Arch addressing
  "10.100.75.0/24" = { az = "eu-west-2b", set = "natgw" }
}

security_vpc_endpoints = {}

security_vpc_security_groups = {
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
        cidr_blocks = ["10.100.1.0/24", "10.100.65.0/24"]
      }
      health_probe = {
        description = "Permit Port 80 GWLB Health Probe"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["10.100.1.0/24", "10.100.65.0/24"]
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
      ssh2 = {
        description = "Permit traffic from any vpc"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["10.0.0.0/8"]
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
      ssh-from-inet = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      https-from-inet = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      panorama-mgmt = {
        description = "Permit Panorama Management"
        type        = "ingress", from_port = "3978", to_port = "3978", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        description = "Permit Panorama Logging"
        type        = "ingress", from_port = "28443", to_port = "28443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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
      { name = "vmseries01-data", index = "0" },
      { name = "vmseries01-mgmt", index = "1" },
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
      { name = "vmseries02-data", index = "0" },
      { name = "vmseries02-mgmt", index = "1" },
    ]
  }
]

interfaces = [
  # vmseries01
  {
    name                          = "vmseries01-data"
    source_dest_check             = false
    subnet_name                   = "dataa"
    security_group                = "vmseries-data"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries01-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmta"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries01-mgmt"
  },
  # vmseries02
  {
    name                          = "vmseries02-data"
    source_dest_check             = false
    subnet_name                   = "datac"
    security_group                = "vmseries-data"
    private_ip_address_allocation = "dynamic"
  },
  {
    name                          = "vmseries02-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmtc"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries02-mgmt"
  },
]

ssh_key_name = "my_aws_key_pair" # create it manually # TODO: automate

### Security VPC ROUTES ###

summary_cidr_behind_natgw          = "0.0.0.0/0"
summary_cidr_behind_tgw            = "10.0.0.0/8"
summary_cidr_behind_gwlbe_outbound = "0.0.0.0/0"

### NATGW ###

nat_gateway_name = "natgw"

### GWLB ###

gateway_load_balancer_name                   = "security-gwlb"
gateway_load_balancer_endpoint_eastwest_name = "eastwest-gwlb-endpoint"
gateway_load_balancer_endpoint_outbound_name = "outbound-gwlb-endpoint"

### TGW ###

transit_gateway_name                = "tgw"
transit_gateway_asn                 = "65200"
security_transit_gateway_attachment = "security-vpc"

### Application1 VPC ###

app1_vpc_name = "app1-spoke-vpc"
app1_vpc_cidr = "10.200.0.0/23"

app1_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.200.0.16/28" = { az = "eu-west-2a", set = "app1-alb" }
  "10.200.1.16/28" = { az = "eu-west-2b", set = "app1-alb" }
  "10.200.0.32/28" = { az = "eu-west-2a", set = "app1-gwlbe" }
  "10.200.1.32/28" = { az = "eu-west-2b", set = "app1-gwlbe" }
  "10.200.0.48/28" = { az = "eu-west-2a", set = "app1-web" }
  "10.200.1.48/28" = { az = "eu-west-2b", set = "app1-web" }
}

# TODO: check if all the cidrs match the Ref-Arch addressing

app1_vpc_security_groups = {}

### Application1 GWLB ###

# Pull back info from existing GWLB endpoint service in security VPC
existing_gateway_load_balancer_name      = "security-gwlb"
gateway_load_balancer_endpoint_app1_name = "app1-gwlb-endpoint"
app1_transit_gateway_attachment_name     = "app1-vpc"
