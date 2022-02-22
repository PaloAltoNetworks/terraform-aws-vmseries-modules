# General
region = "us-east-1"
name   = "vmseries-example"
global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
}

# VPC
security_vpc_name = "security-vpc-example"
security_vpc_cidr = "10.100.0.0/16"

# Subnets
security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24" = { az = "us-east-1a", set = "mgmt" }
}

# Security Groups
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
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
    }
  }
}

# VM-Series
ssh_key_name     = "CHANGE_ME"
vmseries_version = "10.1.3"
vmseries = {
  vmseries01 = { az = "us-east-1a" }
}

bootstrap_options = {
  plugin-op-commands = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
  type               = "dhcp-client"
  hostname           = ""
  tplname            = ""
  dgname             = ""
  panorama-server    = ""
  panorama-server-2  = ""
  vm-auth-key        = ""
  authcodes          = ""
  op-command-modes   = ""
}

# Routes
security_vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]
