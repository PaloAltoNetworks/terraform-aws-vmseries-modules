variable "global_tags" {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
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
      }
    }
  }
  ```
  EOF

  default = {}
  type    = any
}

variable "name" { default = null }
variable "create_vpc" { default = true }
variable "cidr_block" { default = null }
variable "secondary_cidr_blocks" { default = [] }
variable "create_internet_gateway" { default = false }
variable "use_internet_gateway" { default = false }
variable "enable_dns_support" { default = null }
variable "enable_dns_hostnames" { default = null }
variable "instance_tenancy" { default = null }
variable "assign_generated_ipv6_cidr_block" { default = null }
variable "create_vpn_gateway" { default = false }
variable "vpn_gateway_amazon_side_asn" { default = null }
variable "vpc_tags" { default = {} }
