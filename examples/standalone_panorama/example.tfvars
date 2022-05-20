## General
region         = "us-east-1"
prefix         = "pimielow-test-"
create_ssh_key = true
global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks Panorama NGFW"
  Owner       = "PS Team"
}

## Network
security_vpc_name = "panorama-vpc"
security_vpc_cidr = "10.104.0.0/24"

security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.104.0.0/28" = { az = "us-east-1a", set = "mgmt" }
}

security_vpc_security_groups = {
  panorama_mgmt = {
    name = "panorama_mgmt"
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
}

security_vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]

## Panorama
panorama_ssh_key                     = "panorama"
panorama_az                          = "us-east-1a"
panorama_create_public_ip            = true
panorama_enable_iam_read_only_policy = false
panorama_create_custom_kms_key       = false

panorama_ebs_volumes = [
  {
    name            = "ebs-1"
    ebs_device_name = "/dev/sdb"
    ebs_size        = "2000"
    ebs_encrypted   = true
  },
  {
    name            = "ebs-2"
    ebs_device_name = "/dev/sdc"
    ebs_size        = "2000"
    ebs_encrypted   = true
  }
]