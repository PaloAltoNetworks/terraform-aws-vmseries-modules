# General
region = "us-east-2"
name   = "fosix_vmseries-example"
global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
}

# VPC
security_vpc_name = "fosix_security-vpc-example"
security_vpc_cidr = "10.100.0.0/16"

# Subnets
security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"  = { az = "us-east-2a", set = "mgmt" }
  "10.100.1.0/24"  = { az = "us-east-2a", set = "trust" }
  "10.100.2.0/24"  = { az = "us-east-2a", set = "untrust" }
  "10.100.10.0/24" = { az = "us-east-2b", set = "mgmt" }
  "10.100.11.0/24" = { az = "us-east-2b", set = "trust" }
  "10.100.12.0/24" = { az = "us-east-2b", set = "untrust" }
}

# Security Groups
security_vpc_security_groups = {
  load_balancer = {
    name = "fosix_alb"
    rules = {
      all_inbound = {
        description = "Permit all incoming traffic"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
      }
      fw_traffic = {
        description = "Permit all  traffic to FW"
        type        = "egress", from_port = "0", to_port = "0", protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
      }
      # health_check_traffic = {
      #   description = "Permit all  traffic to FW"
      #   type = "egress", from_port = "0", to_port = "0", protocol = "TCP"
      #   cidr_blocks = ["0.0.0.0/0"]
      # }
    }
  }
  vmseries_mgmt = {
    name = "fosix_vmseries_mgmt"
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
    }
  }
  vmseries_trust = {
    name = "fosix_vmseries_trust"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        description = "Permit All traffic inbound"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
    }
  }
  vmseries_untrust = {
    name = "fosix_vmseries_untrust"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        description = "Permit All traffic inbound"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
    }
  }
}

# VM-Series
ssh_key_name     = "fosix-pub-vm"
vmseries_version = "10.1.3"
vmseries = {
  vmseries01 = { az = "us-east-2a" }
  vmseries02 = { az = "us-east-2b" }
}

bootstrap_options = "plugin-op-commands=aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable;type=dhcp-client;hostname=vms01"

# Routes
security_vpc_routes_outbound_destin_cidrs = "0.0.0.0/0"
