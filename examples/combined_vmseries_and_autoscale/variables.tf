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
  - `security_groups`: map of security groups
  - `subnets`: map of subnets

  Example:
  ```
  vpcs = {
    example_vpc = {
      name = "example-spoke-vpc"
      cidr = "10.104.0.0/16"
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
        "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm" }
        "10.104.128.0/24" = { az = "eu-central-1b", set = "vm" }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    cidr = string
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
      az  = string
      set = string
    }))
  }))
}

### TRANSIT GATEWAY
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

### NAT GATEWAY
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

### VM-SERIES
variable "vmseries_asgs" {
  description = <<-EOF
  A map defining Autoscaling Groups with VM-Series instances.

  Following properties are available:
  - `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama
  - `panos_version`: PAN-OS version used for VM-Series
  - `vpc`: key of VPC
  - `gwlb`: key of GWLB
  - `interfaces`: configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group 
  - `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints
  - `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series
  - `asg_desired_cap`: the number of Amazon EC2 instances that should be running in the group
  - `asg_min_size`: minimum size of the Auto Scaling Group
  - `asg_max_size`: maximum size of the Auto Scaling Group
  - `lambda_vpc_subnet`: key of the VPC and subnet connected by '-' character, where Lambda is deployed
  - `scaling_plan_enabled`: `true` if automatic dynamic scaling policy should be created
  - `scaling_metric_name`: name of the metric used in dynamic scaling policy
  - `scaling_tags`: tags configured for dynamic scaling policy
  - `scaling_target_value`: target value for the metric used in dynamic scaling policy
  - `scaling_statistic`: statistic of the metric. Valid values: Average, Maximum, Minimum, SampleCount, Sum
  - `scaling_cloudwatch_namespace`: name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)

  Example:
  ```
  vmseries_asgs = {
    main_asg = {
      bootstrap_options = {
        mgmt-interface-swap         = "enable"
        plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        panorama-server             = ""
        auth-key                    = ""
        dgname                      = ""
        tplname                     = ""
        dhcp-send-hostname          = "yes"
        dhcp-send-client-id         = "yes"
        dhcp-accept-server-hostname = "yes"
        dhcp-accept-server-domain   = "yes"
      }

      panos_version = "10.2.3"

      vpc  = "security_vpc"
      gwlb = "security_gwlb"

      interfaces = {
        private = {
          device_index   = 0
          security_group = "vmseries_private"
          subnet = {
            "privatea" = "eu-central-1a",
            "privateb" = "eu-central-1b"
          }
          create_public_ip  = false
          source_dest_check = false
        }
        mgmt = {
          device_index   = 1
          security_group = "vmseries_mgmt"
          subnet = {
            "mgmta" = "eu-central-1a",
            "mgmtb" = "eu-central-1b"
          }
          create_public_ip  = true
          source_dest_check = true
        }
        public = {
          device_index   = 2
          security_group = "vmseries_public"
          subnet = {
            "publica" = "eu-central-1a",
            "publicb" = "eu-central-1b"
          }
          create_public_ip  = false
          source_dest_check = false
        }
      }

      subinterfaces = {
        inbound1 = "ethernet1/1.11"
        inbound2 = "ethernet1/1.12"
        outbound = "ethernet1/1.20"
        eastwest = "ethernet1/1.30"
      }

      ebs_kms_id = "alias/aws/ebs"

      asg_desired_cap = 1
      asg_min_size    = 1
      asg_max_size    = 2

      lambda_vpc_subnet = "security_vpc-lambda"

      scaling_plan_enabled = true
      scaling_metric_name  = "panSessionActive"
      scaling_tags = {
        ManagedBy = "terraform"
      }
      scaling_target_value         = 75
      scaling_statistic            = "Average"
      scaling_cloudwatch_namespace = "example-vmseries"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
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

    vpc  = string
    gwlb = string

    interfaces = map(object({
      device_index      = number
      security_group    = string
      subnet            = map(string)
      create_public_ip  = bool
      source_dest_check = bool
    }))

    subinterfaces = map(string)

    ebs_kms_id = string

    asg_desired_cap = number
    asg_min_size    = number
    asg_max_size    = number

    lambda_vpc_subnet = string

    scaling_plan_enabled         = bool
    scaling_metric_name          = string
    scaling_tags                 = map(string)
    scaling_target_value         = number
    scaling_statistic            = string
    scaling_cloudwatch_namespace = string
  }))
}

### PANORAMA
variable "panorama" {
  description = <<-EOF
  A object defining TGW attachment and CIDR for Panorama.

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
variable "spoke_lbs" {
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
