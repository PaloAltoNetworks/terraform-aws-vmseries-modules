# COMMON VARIABLES
variable "region" {
  description = "AWS region used to deploy the resources."
  type        = string
}

variable "name_prefix" {
  description = "A prefix to add to all AWS object names."
  default     = ""
  type        = string
}

variable "global_tags" {
  description = "Tags to add to all AWS objects."
  default     = {}
  type        = map(string)
}

# SECURITY VPC CONFIGURATION
variable "security_vpc_name" {
  description = "Name of the VPC used for deploying Firewalls."
  default     = "security-vpc"
  type        = string
}

variable "security_vpc_cidr" {
  description = "Address range for the security VPC."
  default     = "10.100.0.0/16"
  type        = string
}

variable "security_vpc_subnets" {
  description = <<-EOF
  Definition of all subnets in the security VPC.
  
  This is a map where key is the subnet's CIDR and value contains a map consisting of the Availability Zone (in which the subnet will be created) and the subnet set name. 
  
  The latter is used to identify a purpose of the subnet, for example: management, trust, tgw, etc. This property is used later on in the code to reference all subnets of the same type/purpose.

  EXAMPLE:
  ```
  security_vpc_subnets = {
    "10.0.0.0/24" = {
      az = "us-east-1a"
      set = "management"
    }
  }
  ```
  EOF
  type        = map(any)
}

variable "security_vpc_security_groups" {
  description = <<-EOF
  A map containing a definition of all security groups for the Security VPC.

  EXAMPLE:
  ```
  security_vpc_security_groups = {
    untrust = {
      name = "untrust-security-group"
      rules = {
        all_inbound = {
          description = "Permit all incoming traffic"
          type        = "ingress", from_port = "0", to_port = "0", protocol = "ALL"
          cidr_blocks = ["0.0.0.0/0"]
        }
        fw_traffic = {
          description = "Permit all outgoing traffic"
          type        = "egress", from_port = "0", to_port = "0", protocol = "ALL"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
  ```
  EOF
  type        = any
}

# VMSERIES CONFIGURATION
variable "vmseries" {
  description = "Definition of VMSeries VMs. Please refer to [VMSeries module](../../modules/vmseries/README.md) for details"
  type        = any
}

variable "vmseries_version" {
  description = "Version of the VMSeries firewall. Please verify if the version you require is available in your region of choice."
  type        = string
}

variable "ssh_key_name" {
  description = "A name of an existing AWS Key Pair object holding you SSH public key in AWS region of choice."
  type        = string
}

variable "bootstrap_options" {
  description = "A string representing bootstrap options. For details refer to [Palo Alto documentation](https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-the-vm-series-firewall-in-aws)."
  type        = string
}

# LOAD BALANCERS IN FRONT OF THE FIREWALLS CONFIGURATION
variable "network_lb_name" {
  description = "Name of the public Network Load Balancer placed in front of the Firewalls' public interfaces."
  default     = "public-nlb"
  type        = string
}

variable "network_lb_rules" {
  description = <<-EOF
  A map of rules for the public Network Load Balancer. See [modules documentation](../../modules/nlb/README.md) for details.

  NOTICE. In this example we skip the `target_type` and `targets` properties, as this is a public Load Balancer in front of Firewall's public interfaces.
  The target type will be always `ip` and the `targets` - a map of Firewall's public interface private IP addresses. 
  The targets are *combined* with rules in `locals` section in `main.tf`.
  EOF
  type        = any
}

variable "application_lb_name" {
  description = "Name of the public Application Load Balancer placed in front of the Firewalls' public interfaces."
  default     = "public-alb"
  type        = string
}

variable "application_lb_rules" {
  description = "A map of rules for the Application Load Balancer. See [modules documentation](../../modules/alb/README.md) for details."
  type        = any
}

# APPLICATION VPC CONFIGURATION
variable "app_vpc_name" {
  description = "Name of the VPC used for deploying applications."
  default     = "app-vpc"
  type        = string
}

variable "app_vpc_cidr" {
  description = "Address range for the application VPC."
  default     = "10.200.0.0/16"
  type        = string
}

variable "app_vpc_subnets" {
  description = "A map containing configuration of all Application VPC subnets. For details refer to `security_vpc_subnets` description."
  type        = map(any)
}

variable "app_vpc_security_groups" {
  description = "Definition of Security Groups used in Application VPC. For details and example see `security_vpc_security_groups` details."
  type        = any
}

# APPLICATION INFRASTRUCTURE CONFIGURATION
variable "app_vms" {
  description = <<-EOF
  Definition of an exemplary Application VMs. They are based on the latest version of Bitnami's NGINX image.

  The structure of this map is similar to the one defining VMSeries, only one property is supported though: the Availability Zone the VM should be placed in.

  EXAMPLE:
  ```
  app_vms = {
    "appvm01" = { az = "us-east-1b" }
    "appvm02" = { az = "us-east-1a" }
  }
  ```
  EOF
  type        = map(any)
}

variable "internal_app_nlb_name" {
  description = "Name of the internal Network Load Balancer placed in front of the application VMs."
  default     = "int-app-nlb"
  type        = string
}

variable "internal_app_nlb_rules" {
  description = <<-EOF
  A set of rules for the Network Load Balancer placed in front of the Application VMs. See [modules documentation](../../modules/nlb/README.md) for details.

  Just like in case of the `network_lb_rules`, `targets` and `target_type` properties are omitted because they are the same for all rules. In this module's use case the type is `instance` and instance IDs are calculated dynamically. Just like in case of the public Network Load Balancer, rules and targets are *combined* in `locals` section of the `applicaton.tf`.
  EOF
  type        = any
}

# TRANSIT GATEWAY CONFIGURATION
variable "transit_gateway_name" {
  description = "The name of the created Transit Gateway."
  default     = "tgw"
  type        = string
}

variable "transit_gateway_asn" {
  description = <<-EOF
  Private Autonomous System Number (ASN) of the Transit Gateway for the Amazon side of a BGP session.
  The range is 64512 to 65534 for 16-bit ASNs and 4200000000 to 4294967294 for 32-bit ASNs.
  EOF
  default     = "65200"
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
  - from_spoke_vpc describes which route table routes the traffic coming from the Spoke (App1) VPC.

  Each of these entries can specify `create = true` which creates a new RT with a `name`.
  With `create = false` the pre-existing RT named `name` is used.
  EOF
}

variable "security_vpc_tgw_attachment_name" {
  description = "A name of a TGW attachment in the security VPC."
  default     = "security-tgw-attachment"
  type        = string
}

variable "app_vpc_tgw_attachment_name" {
  description = "A name of a TGW attachment in the application VPC."
  default     = "app-tgw-attachment"
  type        = string
}
