### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  type        = string
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
}

### VPC
variable "vpcs" {
  description = <<-EOF
  A map defining VPCs with security groups and subnets.

  Following properties are available:
  - `name`: VPC name
  - `cidr`: CIDR for VPC
  - `nacls`: map of network ACLs
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `set`: internal identifier referenced by main.tf
     - `nacl`: key of NACL (can be null)
  - `routes`: map of routes with properties:
     - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
     - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
     - `next_hop_type` - internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint

  Example:
  ```
  vpcs = {
    example_vpc = {
      name = "example-spoke-vpc"
      cidr = "10.104.0.0/16"
      nacls = {
        trusted_path_monitoring = {
          name               = "trusted-path-monitoring"
          rules = {
            allow_inbound = {
              rule_number = 300
              egress      = false
              protocol    = "-1"
              rule_action = "allow"
              cidr_block  = "0.0.0.0/0"
              from_port   = null
              to_port     = null
            }
          }
        }
      }
      security_groups = {
        example_vm = {
          name = "example_vm"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
          }
        }
      }
      subnets = {
        "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }
        "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }
      }
      routes = {
        vm_default = {
          vpc_subnet    = "app1_vpc-app1_vm"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1"
          next_hop_type = "transit_gateway_attachment"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    cidr = string
    nacls = map(object({
      name = string
      rules = map(object({
        rule_number = number
        egress      = bool
        protocol    = string
        rule_action = string
        cidr_block  = string
        from_port   = string
        to_port     = string
      }))
    }))
    security_groups = map(object({
      name = string
      rules = map(object({
        description = string
        type        = string,
        from_port   = string
        to_port     = string,
        protocol    = string
        cidr_blocks = list(string)
      }))
    }))
    subnets = map(object({
      az   = string
      set  = string
      nacl = string
    }))
    routes = map(object({
      vpc_subnet    = string
      to_cidr       = string
      next_hop_key  = string
      next_hop_type = string
    }))
  }))
}

variable "natgws" {
  description = <<-EOF
  A map defining NAT Gateways.

  Following properties are available:
  - `name`: name of NAT Gateway
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character

  Example:
  ```
  natgws = {
    security_nat_gw = {
      name       = "natgw"
      vpc_subnet = "security_vpc-natgw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name       = string
    vpc_subnet = string
  }))
}

variable "tgw" {
  description = <<-EOF
  A object defining Transit Gateway.

  Following properties are available:
  - `create`: set to false, if existing TGW needs to be reused
  - `id`:  id of existing TGW or null
  - `name`: name of TGW to create or use
  - `asn`: ASN number
  - `route_tables`: map of route tables
  - `attachments`: map of TGW attachments

  Example:
  ```
  tgw = {
    create = true
    id     = null
    name   = "tgw"
    asn    = "64512"
    route_tables = {
      "from_security_vpc" = {
        create = true
        name   = "from_security"
      }
    }
    attachments = {
      security = {
        name                = "vmseries"
        vpc_subnet          = "security_vpc-tgw_attach"
        route_table         = "from_security_vpc"
        propagate_routes_to = "from_spoke_vpc"
      }
    }
  }
  ```
  EOF
  default     = null
  type = object({
    create = bool
    id     = string
    name   = string
    asn    = string
    route_tables = map(object({
      create = bool
      name   = string
    }))
    attachments = map(object({
      name                = string
      vpc_subnet          = string
      route_table         = string
      propagate_routes_to = string
    }))
  })
}

### GATEWAY LOADBALANCER
variable "gwlbs" {
  description = <<-EOF
  A map defining Gateway Load Balancers.

  Following properties are available:
  - `name`: name of the GWLB
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character

  Example:
  ```
  gwlbs = {
    security_gwlb = {
      name       = "security-gwlb"
      vpc_subnet = "security_vpc-gwlb"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name       = string
    vpc_subnet = string
  }))
}

variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `gwlb`: key of GWLB
  - `vpc`: key of VPC
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
  - `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint

  Example:
  ```
  gwlb_endpoints = {
    security_gwlb_eastwest = {
      name            = "eastwest-gwlb-endpoint"
      gwlb            = "security_gwlb"
      vpc             = "security_vpc"
      vpc_subnet      = "security_vpc-gwlbe_eastwest"
      act_as_next_hop = false
      to_vpc_subnets  = null
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name            = string
    gwlb            = string
    vpc             = string
    vpc_subnet      = string
    act_as_next_hop = bool
    to_vpc_subnets  = string
  }))
}

### PANORAMA
variable "panorama_connection" {
  description = <<-EOF
  An object defining TGW attachment and CIDR for Panorama.


  Following properties are available:
  - `transit_gateway_attachment_id`: ID of attachment for Panorama
  - `vpc_cidr`: CIDR of the VPC, where Panorama is deployed

  Example:
  ```
  panorama = {
    transit_gateway_attachment_id = "tgw-attach-123456789"
    vpc_cidr                      = "10.255.0.0/24"
  }
  ```
  EOF
  default     = null
  type = object({
    transit_gateway_attachment_id = string
    vpc_cidr                      = string
  })
}

### VM-SERIES
variable "vmseries" {
  description = <<-EOF
  A map defining VM-Series instances
  Following properties are available:
  - `instances`: map of VM-Series instances
  - `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama
  - `panos_version`: PAN-OS version used for VM-Series
  - `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series
  - `vpc`: key of VPC
  - `gwlb`: key of GWLB
  - `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints
  - `system_services`: map of system services
  - `application_lb`: ALB placed in front of the Firewalls' public interfaces
  - `network_lb`: NLB placed in front of the Firewalls' public interfaces
  Example:
  ```
  vmseries = {
    vmseries = {
      instances = {
        "01" = { az = "eu-central-1a" }
        "02" = { az = "eu-central-1b" }
      }
      # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
      bootstrap_options = {
        mgmt-interface-swap         = "enable"
        plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        dhcp-send-hostname          = "yes"
        dhcp-send-client-id         = "yes"
        dhcp-accept-server-hostname = "yes"
        dhcp-accept-server-domain   = "yes"
      }
      panos_version = "10.2.3"        # TODO: update here
      ebs_kms_id    = "alias/aws/ebs" # TODO: update here
      # Value of `vpc` must match key of objects stored in `vpcs`
      vpc = "security_vpc"
      # Value of `gwlb` must match key of objects stored in `gwlbs`
      gwlb = "security_gwlb"
      interfaces = {
        private = {
          device_index      = 0
          security_group    = "vmseries_private"
          vpc_subnet        = "security_vpc-private"
          create_public_ip  = false
          source_dest_check = false
        }
        mgmt = {
          device_index      = 1
          security_group    = "vmseries_mgmt"
          vpc_subnet        = "security_vpc-mgmt"
          create_public_ip  = true
          source_dest_check = true
        }
        public = {
          device_index      = 2
          security_group    = "vmseries_public"
          vpc_subnet        = "security_vpc-public"
          create_public_ip  = true
          source_dest_check = false
        }
      }
      # Value of `gwlb_endpoint` must match key of objects stored in `gwlb_endpoints`
      subinterfaces = {
        inbound = {
          app1 = {
            gwlb_endpoint = "app1_inbound"
            subinterface  = "ethernet1/1.11"
          }
          app2 = {
            gwlb_endpoint = "app2_inbound"
            subinterface  = "ethernet1/1.12"
          }
        }
        outbound = {
          only_1_outbound = {
            gwlb_endpoint = "security_gwlb_outbound"
            subinterface  = "ethernet1/1.20"
          }
        }
        eastwest = {
          only_1_eastwest = {
            gwlb_endpoint = "security_gwlb_eastwest"
            subinterface  = "ethernet1/1.30"
          }
        }
      }
      system_services = {
        dns_primary = "4.2.2.2"      # TODO: update here
        dns_secondy = null           # TODO: update here
        ntp_primary = "pool.ntp.org" # TODO: update here
        ntp_secondy = null           # TODO: update here
      }
      application_lb = null
      network_lb     = null
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    instances = map(object({
      az = string
    }))

    bootstrap_options = object({
      mgmt-interface-swap         = string
      plugin-op-commands          = string
      panorama-server             = string
      auth-key                    = string
      dgname                      = string
      tplname                     = string
      dhcp-send-hostname          = string
      dhcp-send-client-id         = string
      dhcp-accept-server-hostname = string
      dhcp-accept-server-domain   = string
    })

    panos_version = string
    ebs_kms_id    = string

    vpc  = string
    gwlb = string

    interfaces = map(object({
      device_index      = number
      security_group    = string
      vpc_subnet        = string
      create_public_ip  = bool
      source_dest_check = bool
    }))

    subinterfaces = map(map(object({
      gwlb_endpoint = string
      subinterface  = string
    })))

    system_services = object({
      dns_primary = string
      dns_secondy = string
      ntp_primary = string
      ntp_secondy = string
    })

    application_lb = object({
      name  = string
      rules = any
    })

    network_lb = object({
      name  = string
      rules = any
    })
  }))
}

### SPOKE VMS
variable "spoke_vms" {
  description = <<-EOF
  A map defining VMs in spoke VPCs.

  Following properties are available:
  - `az`: name of the Availability Zone
  - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `security_group`: security group assigned to ENI used by VM
  - `type`: EC2 type VM

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      vpc_subnet     = "app1_vpc-app1_vm"
      security_group = "app1_vm"
      type           = "t2.micro"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    az             = string
    vpc            = string
    vpc_subnet     = string
    security_group = string
    type           = string
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_nlbs" {
  description = <<-EOF
  A map defining Network Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `vms`: keys of spoke VMs

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc_subnet = "app1_vpc-app1_lb"
      vms        = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    vpc_subnet = string
    vms        = list(string)
  }))
}

variable "spoke_albs" {
  description = <<-EOF
  A map defining Application Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `rules`: Rules defining the method of traffic balancing
  - `vms`: Instances to be the target group for ALB
  - `vpc`: The VPC in which the load balancer is to be run
  - `vpc_subnet`: The subnets in which the Load Balancer is to be run
  - `security_gropus`: Security Groups to be associated with the ALB
  ```
  EOF
  type = map(object({
    rules           = any
    vms             = list(string)
    vpc             = string
    vpc_subnet      = string
    security_groups = string
  }))
}