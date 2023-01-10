variable "region" {
  description = "AWS region to use for the created resources."
  default     = "us-east-1"
  type        = string
}

variable "create_iam_role_policy" {
  description = "If true, a new IAM role with policy will be created. When false, name of existing IAM role to use has to be provided in `iam_role_name` variable."
  default     = true
  type        = string
}

variable "iam_role_name" {
  description = "Name of a IAM role to reuse or create (depending on `create_iam_role_policy` value)."
  default     = ""
  type        = string
}

variable "dhcp_send_hostname" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall sends its hostname to the DHCP server."
  default     = "yes"
  type        = string
}

variable "dhcp_send_client_id" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall sends its client ID to the DHCP server."
  default     = "yes"
  type        = string
}

variable "dhcp_accept_server_hostname" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall accepts its hostname from the DHCP server."
  default     = "yes"
  type        = string
}

variable "dhcp_accept_server_domain" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall accepts its DNS server from the DHCP server."
  default     = "yes"
  type        = string
}
