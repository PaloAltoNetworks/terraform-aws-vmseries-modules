# General
region      = "us-east-1"
name_prefix = "example-" # TODO: please change before running Terraform apply
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
ssh_key_name     = "example-ssh-key"
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

# Bootstrap options
bootstrap_options = {
  type             = "dhcp-client",
  aws-gwlb-inspect = "enable"
}

# Routes
security_vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]

# IAM roles and S3 buckets for VM series bootstrap
create_iam_role_policy = true # change to false if you want to reuse existing IAM role
iam_role_name          = ""   # if create_iam_role_policy==false, then please put IAM role name
create_bucket          = true # change to false, if you want to reuse existing bucket
bucket_name            = ""   # specify bucket name, if you don't want to use random name
source_root_directory  = ""   # specify folder with configuration files for bootstrap, if you need it