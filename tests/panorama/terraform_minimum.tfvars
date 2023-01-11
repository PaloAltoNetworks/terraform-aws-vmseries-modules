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
panorama_create_public_ip = false
panorama_ebs_encrypted    = false

panorama_ebs_volumes = []
