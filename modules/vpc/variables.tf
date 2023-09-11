variable "name" {
  description = "Name of the VPC to create or use."
  type        = string
}

variable "create_vpc" {
  description = "When set to `true` inputs are used to create a VPC, otherwise - to get data about an existing one (based on the `name` value)."
  default     = true
  type        = bool
}

variable "cidr_block" {
  description = "CIDR block to assign to a new VPC."
  default     = null
  type        = string
}

variable "secondary_cidr_blocks" {
  description = "Secondary CIDR block to assign to a new VPC."
  default     = []
  type        = list(string)
}

variable "assign_generated_ipv6_cidr_block" {
  description = "A boolean flag to assign AWS-provided /56 IPv6 CIDR block. [Defaults false](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#assign_generated_ipv6_cidr_block)"
  default     = null
  type        = bool
}

variable "use_internet_gateway" {
  description = "If an existing VPC is provided and has IG attached, set to `true` to reuse it."
  default     = false
}

variable "create_internet_gateway" {
  description = "Set to `true` to create IG and attach it to the VPC."
  default     = false
}

variable "name_internet_gateway" {
  description = "Name of the IGW to create or use."
  type        = string
  default     = null
}

variable "route_table_internet_gateway" {
  description = "Name of route table for the IGW."
  type        = string
  default     = null
}

variable "create_vpn_gateway" {
  description = "When set to true, create VPN gateway and a dedicated route table."
  default     = false
  type        = bool
}
variable "vpn_gateway_amazon_side_asn" {
  description = "ASN for the Amazon side of the gateway."
  default     = null
  type        = string
}

variable "name_vpn_gateway" {
  description = "Name of the VPN gateway to create."
  type        = string
  default     = null
}

variable "route_table_vpn_gateway" {
  description = "Name of the route table for VPN gateway."
  type        = string
  default     = null
}

variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC. [Defaults true](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#enable_dns_support)."
  default     = null
  type        = bool
}
variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC. [Defaults false](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#enable_dns_hostnames)."
  default     = null
  type        = bool
}

variable "instance_tenancy" {
  description = "VPC level [instance tenancy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#instance_tenancy)."
  default     = null
  type        = string
}

variable "global_tags" {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}

variable "vpc_tags" {
  description = "Optional map of arbitrary tags to apply to VPC resource."
  default     = {}
}

variable "nacls" {
  description = <<EOF
  The `nacls` variable is a map of maps, where each map represents an AWS NACL.

  Example:
  ```
  nacls = {
    trusted_path_monitoring = {
      name = "trusted-path-monitoring"
      rules = {
        block_outbound_icmp = {
          rule_number = 110
          egress      = true
          protocol    = "icmp"
          rule_action = "deny"
          cidr_block  = "10.100.1.0/24"
          from_port   = null
          to_port     = null
        }
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
  ```
  EOF
  default     = {}
  type        = any
}

variable "security_groups" {
  description = <<EOF
  The `security_groups` variable is a map of maps, where each map represents an AWS Security Group.
  The key of each entry acts as the Security Group name.
  List of available attributes of each Security Group entry:
  - `rules`: A list of objects representing a Security Group rule. The key of each entry acts as the name of the rule and
      needs to be unique across all rules in the Security Group.
      List of attributes available to define a Security Group rule:
      - `description`: Security Group description.
      - `type`: Specifies if rule will be evaluated on ingress (inbound) or egress (outbound) traffic.
      - `cidr_blocks`: List of CIDR blocks - for ingress, determines the traffic that can reach your instance. For egress
      Determines the traffic that can leave your instance, and where it can go.
      - `prefix_list_ids`: List of Prefix List IDs
      - `self`: security group itself will be added as a source to the rule.  Cannot be specified with cidr_blocks, or security_groups.
      - `source_security_groups`: list of security group IDs to be used as a source to the rule. Cannot be specified with cidr_blocks, or self.


  Example:
  ```
  security_groups = {
    vmseries-mgmt = {
      name = "vmseries-mgmt"
      rules = {
        all-outbound = {
          description = "Permit All traffic outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https-inbound-private = {
          description = "Permit HTTPS for VM-Series Management"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
        }
        https-inbound-eip = {
          description = "Permit HTTPS for VM-Series Management from known public IPs"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["100.100.100.100/32"]
        }
        ssh-inbound-eip = {
          description = "Permit SSH for VM-Series Management from known public IPs"
          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
          cidr_blocks = ["100.100.100.100/32"]
        }
        https-inbound-self = {
          description = "Permit HTTPS from instances with the same security group"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          self        = true
        }
        https-inbound-security-groups = {
          description = "Permit HTTPS traffic for the resources associated with the specified security group"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          source_security_groups = ["sg-1a2b3c4d5e6f7g8h9i"]
        }
        https-inbound-prefix-list = {
          description = "Permit HTTPS for VM-Series Management for IPs in managed prefix list"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          prefix_list_ids = ["pl-1a2b3c4d5e6f7g8h9i"]
        }
      }
    }
  }
  ```
  EOF

  default = {}
  type    = any
}

variable "create_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers."
  default     = false
  type        = bool
}
variable "domain_name" {
  description = "Specifies DNS name for DHCP options set. 'create_dhcp_options' needs to be enabled."
  default     = ""
  type        = string
}
variable "domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided"
  default     = []
  type        = list(string)
}
variable "ntp_servers" {
  description = "Specify a list of NTP server addresses for DHCP options set, default to AWS provided"
  default     = []
  type        = list(string)
}