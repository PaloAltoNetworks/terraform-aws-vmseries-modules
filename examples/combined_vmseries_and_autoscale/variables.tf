### General
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

### VM-Series
variable "vmseries_common" {
  description = <<-EOF
  Common VM-Seriess like bootstrap options or network subinterfaces used to map with GWLB endpoints e.g.:

  vmseries_common = {
    bootstrap_options = {
      mgmt-interface-swap = "enable"
      plugin-op-commands  = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
      panorama-server     = ""
      auth-key            = ""
      dgname              = "example"
      tplname             = "example-stack"
    }
    subinterfaces = {
      inbound1 = "ethernet1/1.11"
      inbound2 = "ethernet1/1.12"
      outbound = "ethernet1/1.20"
      eastwest = "ethernet1/1.30"
    }
  }
  EOF
}
variable "vmseries_version" {
  description = "PAN-OS version used for VM-Series"
  type        = string
}
variable "vmseries_interfaces" {
  description = <<-EOF
  Configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group e.g.:

  vmseries_interfaces = {
    data1 = {
      device_index   = 0
      security_group = "vmseries_data"
      subnet = {
        "data1a" = "eu-central-1a",
        "data1b" = "eu-central-1b"
      }
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
  }
  EOF
}

variable "ebs_kms_id" {
  description = "Alias for AWS KMS used for EBS encryption in VM-Series"
  type        = string
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}
variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}
variable "asg_desired_cap" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  type        = number
}

variable "scaling_plan_enabled" {
  description = "True, if automatic dynamic scaling policy should be created"
  type        = bool
}
variable "scaling_metric_name" {
  description = "Name of the metric used in dynamic scaling policy"
  type        = string
}
variable "scaling_tags" {
  description = "Tags configured for dynamic scaling policy"
}
variable "scaling_target_value" {
  description = "Target value for the metric used in dynamic scaling policy"
  type        = number
}
variable "scaling_cloudwatch_namespace" {
  description = "Name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)"
  type        = string
}

### Security VPC
variable "security_vpc_name" {
  description = "Name of the security VPC"
  type        = string
}
variable "security_vpc_cidr" {
  description = "IPv4 CIDR for the security VPC"
  type        = string
}
variable "security_vpc_subnets" {
  description = <<-EOF
  Map of subnets configured in the security VPC e.g.: 

  security_vpc_subnets = {
    # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
    "10.100.0.0/24"  = { az = "eu-central-1a", set = "mgmt" }
    "10.100.64.0/24" = { az = "eu-central-1b", set = "mgmt" }
    "10.100.1.0/24"  = { az = "eu-central-1a", set = "data1" }
    "10.100.65.0/24" = { az = "eu-central-1b", set = "data1" }
    "10.100.3.0/24"  = { az = "eu-central-1a", set = "tgw_attach" }
    "10.100.67.0/24" = { az = "eu-central-1b", set = "tgw_attach" }
    "10.100.4.0/24"  = { az = "eu-central-1a", set = "gwlbe_outbound" }
    "10.100.68.0/24" = { az = "eu-central-1b", set = "gwlbe_outbound" }
    "10.100.5.0/24"  = { az = "eu-central-1a", set = "gwlb" }
    "10.100.69.0/24" = { az = "eu-central-1b", set = "gwlb" }
    "10.100.10.0/24" = { az = "eu-central-1a", set = "gwlbe_eastwest" }
    "10.100.74.0/24" = { az = "eu-central-1b", set = "gwlbe_eastwest" }
    "10.100.11.0/24" = { az = "eu-central-1a", set = "natgw" }
    "10.100.75.0/24" = { az = "eu-central-1b", set = "natgw" }
    "10.100.12.0/24" = { az = "eu-central-1a", set = "lambda" }
    "10.100.76.0/24" = { az = "eu-central-1b", set = "lambda" }
  }

  EOF
}
variable "security_vpc_security_groups" {
  description = <<-EOF
  Map of security groups configured in the security VPC e.g.:

  security_vpc_security_groups = {
    vmseries_data = {
      name = "vmseries_data"
      rules = {
        all_outbound = {
          description = "Permit All traffic outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        geneve = {
          description = "Permit GENEVE to GWLB subnets"
          type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
          cidr_blocks = [
            "10.100.5.0/24", "10.100.69.0/24", "10.100.132.0/24", "10.100.201.0/24", "10.100.6.0/24", "10.100.70.0/24"
          ]
        }
        health_probe = {
          description = "Permit Port 80 Health Probe to GWLB subnets"
          type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
          cidr_blocks = [
            "10.100.5.0/24", "10.100.69.0/24", "10.100.132.0/24", "10.100.201.0/24", "10.100.6.0/24", "10.100.70.0/24"
          ]
        }
      }
    }
  }

  EOF
}

#### Security VPC Routes
variable "security_vpc_routes_outbound_source_cidrs" {
  description = <<-EOF
  From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing outside.
  Used for return traffic routes post-inspection.
  A list of strings, for example `[\"10.0.0.0/8\"]`.
  EOF
  type        = list(string)
}

variable "security_vpc_routes_outbound_destin_cidrs" {
  description = <<-EOF
  From the perspective of Security VPC, the destination addresses of packets coming from TGW and flowing outside.
  A list of strings, for example `[\"0.0.0.0/0\"]`.
  EOF
  type        = list(string)
}

variable "security_vpc_mgmt_routes_to_tgw" {
  description = <<-EOF
  The eastwest inspection of traffic heading to VM-Series management interface is not possible.
  Due to AWS own limitations, anything from the TGW destined for the management interface could *not* possibly override LocalVPC route.
  Henceforth no management routes go back to gwlbe_eastwest.
  EOF
  type        = list(string)
}

variable "security_vpc_routes_eastwest_cidrs" {
  description = <<-EOF
  From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing back to TGW.
  A list of strings, for example `[\"10.0.0.0/8\"]`.
  EOF
  type        = list(string)
}

#### Security VPC TGW attachments
variable "security_vpc_tgw_attachment_name" {
  description = "Name of TGW attachment for the security VPC"
  type        = string
}
variable "panorama_transit_gateway_attachment_id" {
  description = "ID of TGW attachment for Panorama"
  default     = null
  type        = string
}
variable "panorama_vpc_cidr" {
  description = "IPv4 CIDR of the VPC for Panorama"
  default     = null
  type        = string
}

### Transit gateway
variable "transit_gateway_id" {
  description = "The ID of the existing Transit Gateway."
  type        = string
  default     = null
}

variable "transit_gateway_name" {
  description = "The name tag of the created Transit Gateway."
  type        = string
}

variable "transit_gateway_asn" {
  description = <<-EOF
  Private Autonomous System Number (ASN) of the Transit Gateway for the Amazon side of a BGP session.
  The range is 64512 to 65534 for 16-bit ASNs and 4200000000 to 4294967294 for 32-bit ASNs.
  EOF
  type        = number
}

variable "transit_gateway_route_tables" {
  description = <<-EOF
  Complex input with the Route Tables of the Transit Gateway. Example:

  ```
  {
    "from_security_vpc" = {
      create = true
      name   = "myrt1"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "myrt2"
    }
  }
  ```

  Two keys are required:

  - from_security_vpc describes which route table routes the traffic coming from the Security VPC,
  - from_spoke_vpc describes which route table routes the traffic coming from the Spoke (app1, app2) VPC.

  Each of these entries can specify `create = true` which creates a new RT with a `name`.
  With `create = false` the pre-existing RT named `name` is used.
  EOF
}

variable "transit_gateway_create" {
  description = "False if using existing TGW, true if new TGW needs to be created"
  type        = bool
  default     = true
}

### GWLB
variable "gwlb_name" {
  description = "Name of the GWLB"
  type        = string
}
variable "gwlb_endpoint_set_eastwest_name" {
  description = "Name of the set with GWLB endpoints for east-west traffic"
  type        = string
}
variable "gwlb_endpoint_set_outbound_name" {
  description = "Name of the set with GWLB endpoints for outbound traffic"
  type        = string
}

### NAT GW
variable "nat_gateway_name" {
  description = "Name of the NAT gateway"
  type        = string
}

### SPOKE VPC APP1
variable "app1_transit_gateway_attachment_name" {
  description = "The name of the TGW Attachment to be created inside the app1 VPC."
  type        = string
}

variable "app1_gwlb_endpoint_set_name" {
  description = "The name of the GWLB VPC Endpoint created to inspect traffic inbound from Internet to the app1 load balancer."
  type        = string
}

variable "app1_vpc_name" {
  description = "The name tag of the created app1 VPC."
  type        = string
}

variable "app1_vpc_cidr" {
  description = "The primary IPv4 CIDR of the created app1 VPC."
  type        = string
}

variable "app1_vpc_subnets" {
  description = "Map of subnets in app1 VPC"
}
variable "app1_vpc_security_groups" {
  description = "Map of security groups in app1 VPC"
}

variable "app1_vm_type" {
  description = "EC2 type for \"app1\" VMs."
  default     = "t2.micro"
  type        = string
}

variable "app1_vms" {
  description = <<-EOF
  Definition of an example "app1" application VMs. They are based on the latest version of Bitnami's NGINX image.
  The structure of this map is similar to the one defining VM-Series, only one property is supported though: the Availability Zone the VM should be placed in.
  Example:

  ```
  app_vms = {
    "appvm01" = { az = "us-east-1b" }
    "appvm02" = { az = "us-east-1a" }
  }
  ```
  EOF
  type        = map(any)
}

### SPOKE VPC APP2
variable "app2_transit_gateway_attachment_name" {
  description = "The name of the TGW Attachment to be created inside the app2 VPC."
  type        = string
}

variable "app2_gwlb_endpoint_set_name" {
  description = "The name of the GWLB VPC Endpoint created to inspect traffic inbound from Internet to the app2 load balancer."
  type        = string
}

variable "app2_vpc_name" {
  description = "The name tag of the created app2 VPC."
  type        = string
}

variable "app2_vpc_cidr" {
  description = "The primary IPv4 CIDR of the created app2 VPC."
  type        = string
}

variable "app2_vpc_subnets" {
  description = "Map of subnets in app1 VPC"
}
variable "app2_vpc_security_groups" {
  description = "Map of security groups in app1 VPC"
}

variable "app2_vm_type" {
  description = "EC2 type for \"app2\" VMs."
  default     = "t2.micro"
  type        = string
}

variable "app2_vms" {
  description = <<-EOF
  Definition of an example "app2" application VMs. They are based on the latest version of Bitnami's NGINX image.
  The structure of this map is similar to the one defining VM-Series, only one property is supported though: the Availability Zone the VM should be placed in.
  Example:

  ```
  app_vms = {
    "appvm01" = { az = "us-east-1b" }
    "appvm02" = { az = "us-east-1a" }
  }
  ```
  EOF
  type        = map(any)
}
