### General
region      = "eu-west-1" # TODO: update here
name_prefix = "example-"     # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### VPC
vpcs = {
  # Do not use `-` in key for VPC as this character is used in concatation of VPC and subnet for module `subnet_set` in `main.tf`
  management_vpc = {
    name = "management-vpc"
    cidr = "10.255.0.0/16"
    security_groups = {
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
            cidr_blocks = ["130.41.247.0/24"] # TODO: update here
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24"] # TODO: update here
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      "10.255.0.0/24" = { az = "eu-west-1a", set = "mgmt" }
      "10.255.1.0/24" = { az = "eu-west-1b", set = "mgmt" }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys used to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_default = {
        vpc_subnet    = "management_vpc-mgmt"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "management_vpc"
        next_hop_type = "internet_gateway"
      }
    }
  }
}

### PANORAMA instances
panoramas = {
  panorama_ha_pair = {
    instances = {
      "primary" = {
        az                 = "eu-west-1a"
        private_ip_address = "10.255.0.4"
      }
      "secondary" = {
        az                 = "eu-west-1b"
        private_ip_address = "10.255.1.4"
      }
    }

    panos_version = "10.2.3"

    network = {
      vpc              = "management_vpc"
      vpc_subnet       = "management_vpc-mgmt"
      security_group   = "panorama_mgmt"
      create_public_ip = true
    }

    ebs = {
      volumes = [
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
      kms_key_alias = "aws/ebs"
    }

    iam = {
      create_role = true
      role_name   = "panorama"
    }

    enable_imdsv2 = false
  }
}
