vpc_cidr = "10.104.0.0/16"
vpc_name = "example-vpc"

region       = "us-east-1"
name_prefix  = "example-asg-"
ssh_key_name = "example_key"

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
}

vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.104.0.0/24"   = { az = "us-east-1a", set = "mgmt_a" }
  "10.104.128.0/24" = { az = "us-east-1b", set = "mgmt_b" }
  "10.104.2.0/24"   = { az = "us-east-1a", set = "data1_a" }
  "10.104.130.0/24" = { az = "us-east-1b", set = "data1_b" }
  "10.104.3.0/24"   = { az = "us-east-1a", set = "data2_a" }
  "10.104.131.0/24" = { az = "us-east-1b", set = "data2_b" }
}

vmseries_interfaces = {
  mgmt = {
    device_index   = 0
    security_group = "vmseries_mgmt"
    subnet = {
      "mgmt_a" = "us-east-1a",
      "mgmt_b" = "us-east-1b"
    }
    create_public_ip  = true
    source_dest_check = true
  }
  data1 = {
    device_index   = 1
    security_group = "vmseries_data"
    subnet = {
      "data1_a" = "us-east-1a",
      "data1_b" = "us-east-1b"
    }
    source_dest_check = true
  }
  data2 = {
    device_index   = 2
    security_group = "vmseries_data"
    subnet = {
      "data2_a" = "us-east-1a",
      "data2_b" = "us-east-1b"
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

asg_desired_cap = 4
asg_min_size    = 1
asg_max_size    = 2