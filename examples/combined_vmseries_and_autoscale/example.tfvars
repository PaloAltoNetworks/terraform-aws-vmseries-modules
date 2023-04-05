### General
region      = "eu-central-1" # TODO: update here
name_prefix = "example-"     # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-frankfurt" # TODO: update here

### VM-Series
vmseries_common = {
  bootstrap_options = {
    mgmt-interface-swap         = "enable"
    plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable" # TODO: if GWLB overlay routing needed, add: ',aws-gwlb-overlay-routing:enable'
    panorama-server             = ""                                                                                   # TODO: update here
    auth-key                    = ""                                                                                   # TODO: update here
    dgname                      = "example"                                                                            # TODO: update here
    tplname                     = "example-stack"                                                                      # TODO: update here
    dhcp-send-hostname          = "yes"                                                                                # TODO: update here
    dhcp-send-client-id         = "yes"                                                                                # TODO: update here
    dhcp-accept-server-hostname = "yes"                                                                                # TODO: update here
    dhcp-accept-server-domain   = "yes"                                                                                # TODO: update here    
  }
  subinterfaces = {
    inbound1 = "ethernet1/1.11"
    inbound2 = "ethernet1/1.12"
    outbound = "ethernet1/1.20"
    eastwest = "ethernet1/1.30"
  }
}

vmseries_version = "10.2.3" # TODO: update here

vmseries_interfaces = {
  private = {
    device_index   = 0
    security_group = "vmseries_private"
    subnet = {
      "privatea" = "eu-central-1a",
      "privateb" = "eu-central-1b"
    }
    source_dest_check = false
  }
  mgmt = {
    device_index   = 1
    security_group = "vmseries_mgmt"
    subnet = {
      "mgmta" = "eu-central-1a",
      "mgmtb" = "eu-central-1b"
    }
    create_public_ip  = true
    source_dest_check = true
  }
  public = {
    device_index   = 2
    security_group = "vmseries_public"
    subnet = {
      "publica" = "eu-central-1a",
      "publicb" = "eu-central-1b"
    }
    source_dest_check = false
  }
}

ebs_kms_id = "alias/aws/ebs"

asg_desired_cap = 1
asg_min_size    = 1
asg_max_size    = 2

scaling_plan_enabled = true               # TODO: update here
scaling_metric_name  = "panSessionActive" # TODO: update here
scaling_tags = {
  ManagedBy = "terraform"
}
scaling_target_value         = 75                 # TODO: update here
scaling_cloudwatch_namespace = "example-vmseries" # TODO: update here

### Security VPC
security_vpc_name = "security-vpc"
security_vpc_cidr = "10.100.0.0/16"

#### Subnets
security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"  = { az = "eu-central-1a", set = "mgmt" }
  "10.100.64.0/24" = { az = "eu-central-1b", set = "mgmt" }
  "10.100.1.0/24"  = { az = "eu-central-1a", set = "private" }
  "10.100.65.0/24" = { az = "eu-central-1b", set = "private" }
  "10.100.2.0/24"  = { az = "eu-central-1a", set = "public" }
  "10.100.66.0/24" = { az = "eu-central-1b", set = "public" }
  "10.100.3.0/24"  = { az = "eu-central-1a", set = "tgw_attach" }
  "10.100.67.0/24" = { az = "eu-central-1b", set = "tgw_attach" }
  "10.100.4.0/24"  = { az = "eu-central-1a", set = "gwlbe_outbound" }
  "10.100.68.0/24" = { az = "eu-central-1b", set = "gwlbe_outbound" }
  "10.100.5.0/24"  = { az = "eu-central-1a", set = "gwlb" }
  "10.100.69.0/24" = { az = "eu-central-1b", set = "gwlb" }
  "10.100.10.0/24" = { az = "eu-central-1a", set = "gwlbe_eastwest" }
  "10.100.74.0/24" = { az = "eu-central-1b", set = "gwlbe_eastwest" }
  "10.100.11.0/24" = { az = "eu-central-1a", set = "natgw" }
  "10.100.75.0/24" = { az = "eu-central-1b", set = "natgw" }
  "10.100.12.0/24" = { az = "eu-central-1a", set = "lambda" }
  "10.100.76.0/24" = { az = "eu-central-1b", set = "lambda" }
}

#### Security groups
security_vpc_security_groups = {
  lambda = {
    name = "lambda"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      all_inbound = {
        description = "Permit All traffic inbound"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
  vmseries_private = {
    name = "vmseries_private"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      geneve = {
        description = "Permit GENEVE to GWLB subnets"
        type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
        cidr_blocks = [
          "10.100.5.0/24", "10.100.69.0/24"
        ]
      }
      health_probe = {
        description = "Permit Port 80 Health Probe to GWLB subnets"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = [
          "10.100.5.0/24", "10.100.69.0/24"
        ]
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
  vmseries_public = {
    name = "vmseries_public"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
      http = {
        description = "Permit HTTP"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
    }
  }
}

#### Security VPC Routes
security_vpc_routes_outbound_source_cidrs = [
  # outbound traffic return after inspection
  "10.0.0.0/8",
]
security_vpc_routes_outbound_destin_cidrs = [
  # outbound traffic incoming for inspection from TGW
  "0.0.0.0/0",
]
security_vpc_routes_eastwest_cidrs = [
  # eastwest traffic incoming for inspection from TGW
  "10.0.0.0/8",
]
security_vpc_mgmt_routes_to_tgw = [
  # Panorama via TGW (must not repeat any security_vpc_routes_eastwest_cidrs)
  "10.255.0.0/16",
]

#### Security VPC TGW attachments
security_vpc_tgw_attachment_name       = "vmseries"
panorama_transit_gateway_attachment_id = null            # TODO: update here
panorama_vpc_cidr                      = "10.255.0.0/24" # TODO: update here

### Transit gateway
transit_gateway_create = true
transit_gateway_id     = null
transit_gateway_name   = "tgw"
transit_gateway_asn    = "64512"
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

### GWLB
gwlb_name                       = "security-gwlb"
gwlb_endpoint_set_eastwest_name = "eastwest-gwlb-endpoint"
gwlb_endpoint_set_outbound_name = "outbound-gwlb-endpoint"

### NAT gateway
nat_gateway_name = "natgw"

### SPOKE VPC APP1
app1_transit_gateway_attachment_name = "app1-spoke-vpc"
app1_gwlb_endpoint_set_name          = "app1-gwlb-endpoint"

app1_vpc_name = "app1-spoke-vpc"
app1_vpc_cidr = "10.104.0.0/16"

app1_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.104.0.0/24"   = { az = "eu-central-1a", set = "app1_vm" }
  "10.104.128.0/24" = { az = "eu-central-1b", set = "app1_vm" }
  "10.104.2.0/24"   = { az = "eu-central-1a", set = "app1_lb" }
  "10.104.130.0/24" = { az = "eu-central-1b", set = "app1_lb" }
  "10.104.3.0/24"   = { az = "eu-central-1a", set = "app1_gwlbe" }
  "10.104.131.0/24" = { az = "eu-central-1b", set = "app1_gwlbe" }
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
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
      http = {
        description = "Permit HTTP"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
    }
  }
}

app1_vms = {
  "app1_vm01" = { az = "eu-central-1a" }
  "app1_vm02" = { az = "eu-central-1b" }
}

### SPOKE VPC APP2
app2_transit_gateway_attachment_name = "app2-spoke-vpc"
app2_gwlb_endpoint_set_name          = "app2-gwlb-endpoint"

app2_vpc_name = "app2-spoke-vpc"
app2_vpc_cidr = "10.105.0.0/16"

app2_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.105.0.0/24"   = { az = "eu-central-1a", set = "app2_vm" }
  "10.105.128.0/24" = { az = "eu-central-1b", set = "app2_vm" }
  "10.105.2.0/24"   = { az = "eu-central-1a", set = "app2_lb" }
  "10.105.130.0/24" = { az = "eu-central-1b", set = "app2_lb" }
  "10.105.3.0/24"   = { az = "eu-central-1a", set = "app2_gwlbe" }
  "10.105.131.0/24" = { az = "eu-central-1b", set = "app2_gwlbe" }
}

app2_vpc_security_groups = {
  app2_vm = {
    name = "app2_vm"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
      http = {
        description = "Permit HTTP"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
      }
    }
  }
}

app2_vms = {
  "app2_vm01" = { az = "eu-central-1a" }
  "app2_vm02" = { az = "eu-central-1b" }
}
