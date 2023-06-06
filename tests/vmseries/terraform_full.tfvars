### General

region      = "us-east-1"
name_prefix = "test-module-vmseries-"
global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
}

### Network

security_vpc_cidr = "10.100.0.0/16"

security_vpc_subnets = {
  "10.100.0.0/24" = { az = "us-east-1a", set = "mgmt" }
  "10.100.1.0/24" = { az = "us-east-1a", set = "data1" }
}

security_vpc_security_groups = {
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
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
  vmseries_data1 = {
    name = "vmseries_data1"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}

security_vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]

### VM-Series

vmseries_version = "10.2.2"
vmseries = {
  vmseries01 = {
    az = "us-east-1a"
    interfaces = {
      mgmt = {
        device_index      = 0
        security_group    = "vmseries_mgmt"
        source_dest_check = true
        subnet            = "mgmt"
        create_public_ip  = true
      }
    }
  }
}

bootstrap_options = "plugin-op-commands=aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable;type=dhcp-client;hostname=vms01"
