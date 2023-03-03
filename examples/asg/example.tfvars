vpc_cidr = "10.104.0.0/16"
vpc_name = "example-vpc"

region       = "us-east-1"
name_prefix  = "example-asg-"
ssh_key_name = "example-key"

global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
}

vpc_security_groups = {
  vmseries_data = {
    name = "vmseries_data"
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
    }
  }
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
}

vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.104.0.0/24"   = { az = "us-east-1a", set = "mgmt" }
  "10.104.128.0/24" = { az = "us-east-1b", set = "mgmt" }
  "10.104.1.0/24"   = { az = "us-east-1a", set = "lambda" }
  "10.104.129.0/24" = { az = "us-east-1b", set = "lambda" }
  "10.104.2.0/24"   = { az = "us-east-1a", set = "data1" }
  "10.104.130.0/24" = { az = "us-east-1b", set = "data1" }
  "10.104.3.0/24"   = { az = "us-east-1a", set = "data2" }
  "10.104.131.0/24" = { az = "us-east-1b", set = "data2" }
  "10.104.4.0/24"   = { az = "us-east-1a", set = "natgw" }
  "10.104.132.0/24" = { az = "us-east-1b", set = "natgw" }
}

vmseries_interfaces = {
  data1 = {
    device_index   = 0
    security_group = "vmseries_data"
    subnet = {
      "data1a" = "us-east-1a",
      "data1b" = "us-east-1b"
    }
    source_dest_check = true
  }
  mgmt = {
    device_index   = 1
    security_group = "vmseries_mgmt"
    subnet = {
      "mgmta" = "us-east-1a",
      "mgmtb" = "us-east-1b"
    }
    create_public_ip  = true
    source_dest_check = true
  }
  data2 = {
    device_index   = 2
    security_group = "vmseries_data"
    subnet = {
      "data2a" = "us-east-1a",
      "data2b" = "us-east-1b"
    }
    source_dest_check = true
  }
}
vmseries_version = "10.2.2"
bootstrap_options = {
  type                = "dhcp-client"
  panorama-server     = "1.2.3.4"
  panorama-server-2   = "3.4.5.6"
  mgmt-interface-swap = "enable"
}
# Routes
security_vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]

asg_desired_cap = 1
asg_min_size    = 1
asg_max_size    = 2
