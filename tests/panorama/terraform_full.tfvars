## General
region      = "us-east-1"
name_prefix = "test-module-panorama-"
global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks Panorama"
  Owner       = "PS Team"
}

## Network
vpc_cidr = "10.104.0.0/24"

vpc_subnets = {
  "10.104.0.0/28" = { az = "us-east-1a", set = "mgmt" }
}

vpc_security_groups = {
  panorama-mgmt = {
    name = "panorama-mgmt"
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

vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]

## IAM Instance Role
panorama_iam_policy_name             = "AmazonEC2ReadOnlyAccess"
panorama_create_iam_instance_profile = true
panorama_create_iam_role             = true

## Panorama
panorama_az               = "us-east-1a"
panorama_create_public_ip = true
panorama_ebs_encrypted    = true

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
