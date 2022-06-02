## General
region                = "us-east-1"
name_prefix           = "example-"
panorama_ssh_key_name = "example-key"
global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks Panorama"
  Owner       = "PS Team"
}

## Network
vpc_name = "panorama-vpc"
vpc_cidr = "10.104.0.0/24"

vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
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
        cidr_blocks = ["36.36.36.36/32"] # TODO: update here
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["36.36.36.36/32"] # TODO: update here
      }
    }
  }
}

vpc_routes_outbound_destin_cidrs = ["0.0.0.0/0"]

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