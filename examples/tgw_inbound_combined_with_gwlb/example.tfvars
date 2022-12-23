region      = "us-east-1"
name        = "vmseries"
name_prefix = "example-"

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
  # Creator     = "login"
}

### Security VPC ###
security_vpc_name = "security-vpc"
security_vpc_cidr = "10.100.0.0/16"
# Routes
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
# Security groups
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
# Subnets
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
# TGW
security_vpc_tgw_attachment_name = "tgw"

### NAT gateway
nat_gateway_name = "natgw"

### GWLB
gwlb_name                       = "security-gwlb"
gwlb_endpoint_set_eastwest_name = "eastwest-gwlb-endpoint"
gwlb_endpoint_set_outbound_name = "outbound-gwlb-endpoint"

### Transit gateway
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

### VM-Series instances
vmseries = {
  vmseries01 = { az = "us-east-1a" }
  vmseries02 = { az = "us-east-1b" }
}
vmseries_common = {
  bootstrap_options = {
    mgmt-interface-swap = "enable"
    plugin-op-commands  = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
  }
  s3_bucket_init_cfg_op_command_modes   = "mgmt-interface-swap"
  s3_bucket_init_cfg_plugin_op_commands = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
  subinterface_inbound                  = "ethernet1/1.10"
  subinterface_outbound                 = "ethernet1/1.20"
  subinterface_eastwest                 = "ethernet1/1.30"
}
vmseries_version = "10.2.2"

# EC2 SSH Key
create_ssh_key = false
# ssh_key_name        = "-->your AWS key pair name goes here<--"


### App1 VPC
app1_transit_gateway_attachment_name = "app1-spoke-vpc"

app1_vpc_name = "app1-spoke-vpc"
app1_vpc_cidr = "10.104.0.0/16"

# Pull back info from existing GWLB in security VPC.
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

app1_vms = {
  "app1_vm01" = { az = "us-east-1a" }
  "app1_vm02" = { az = "us-east-1b" }
}

