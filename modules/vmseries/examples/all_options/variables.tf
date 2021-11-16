variable "base_infra_state_bucket" {
  description = "Name of S3 bucket containing remote state for base infra."
}

variable "base_infra_state_key" {
  description = "Name of key for remote state for base infra."
}

variable "base_infra_state_region" {
  description = "Region for remote state for base infra."
}

variable "panorama_bootstrap_state_key" {
  description = "Name of key for remote state of bootstrap deployment."
}

variable "interfaces" {}
variable "region" {}
variable "tags" {}
variable "ssh_key_name" {}
variable "firewalls" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "fw_instance_type" {}
# variable "pano_version" {}
variable "rts_to_fw_eni" {}
variable "shared_cred_profile" {}
variable "addtional_interfaces" {}
variable "prefix_name_tag" {}
