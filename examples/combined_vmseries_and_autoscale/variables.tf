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
variable "vpcs" {}

### TRANSIT GATEWAY
variable "tgw" {}

### NAT GATEWAY
variable "natgws" {}

### GATEWAY LOADBALANCER
variable "gwlbs" {}
variable "gwlb_endpoints" {}

### VM-SERIES
variable "vmseries_asgs" {}

### PANORAMA
variable "panorama" {}

### SPOKE VMS
variable "spoke_vms" {}

### SPOKE LOADBALANCERS
variable "spoke_lbs" {}