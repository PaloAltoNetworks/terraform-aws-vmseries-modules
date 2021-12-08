variable "global_tags" {
  description = "A map of tags to abe associated with all created resources."
  default     = {}
  type        = map(any)
}

# Panorama version for AMI lookup
variable "panorama_version" {
  description = <<-EOF
  Panorama PAN-OS Software version. List published images with: 
  `aws ec2 describe-images --filters "Name=product-code,Values=eclz7j04vu9lf8ont8ta3n17o" "Name=name,Values=Panorama-AWS*" --output json --query "Images[].Description" | grep -o 'Panorama-AWS-.*' | tr -d '",'`
  default     = "10.0.2"
  type        = string
  EOF
}

# Panorama Deployment Variables
variable "panoramas" {
  description = "Map of Panoramas to be built."
  default     = {}
  type        = any
}

variable "subnets_map" {
  description = <<-EOF
  Map of subnet name to ID, can be passed from remote state output or data source.
  
  Example:

  ```
  subnets_map = {
    "panorama-mgmt-1a" = "subnet-0e1234567890"
    "panorama-mgmt-1b" = "subnet-0e1234567890"
  }
  ```
  EOF
  default     = {}
  type        = map(any)
}

variable "security_groups_map" {
  description = <<-EOF
  Map of security group name to ID, can be passed from remote state output or data source.

  Example:

  ```
  security_groups_map = {
    "panorama-mgmt-inbound-sg" = "sg-0e1234567890"
    "panorama-mgmt-outbound-sg" = "sg-0e1234567890"
  } 
  ```
  EOF
  default     = {}
  type        = map(any)
}
