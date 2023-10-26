variable "global_tags" {
  description = "Map of arbitrary tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix" {
  description = "The prefix to use for bucket name, IAM role name, and IAM role policy name. It is allowed to use dash \"-\" as the last character."
  default     = "bootstrap-"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the instance profile to create. If empty, name will be auto-generated."
  default     = ""
  type        = string
}

variable "create_iam_role_policy" {
  description = "If true, a new IAM role with policy will be created. When false, name of existing IAM role to use has to be provided in `iam_role_name` variable."
  default     = true
  type        = bool
}

variable "iam_role_name" {
  description = "Name of a IAM role to reuse or create (depending on `create_iam_role_policy` value)."
  default     = null
  type        = string
}

variable "force_destroy" {
  description = "Set to false to prevent Terraform from destroying a bucket with unknown objects or locked objects."
  default     = true
  type        = bool
}

variable "source_root_directory" {
  description = "The source directory to become the bucket's root directory. If empty uses `files` subdirectory of a Terraform configuration root directory."
  default     = ""
  type        = string
}

variable "bootstrap_directories" {
  description = "List of subdirectories to be created inside the bucket (whether or not they exist locally inside the `source_root_directory`). A hardcoded pan-os requirement."
  default = [
    "config/",
    "content/",
    "software/",
    "license/",
    "plugins/"
  ]
  type = list(string)
}

### Variables below go to the init-cfg.txt
variable "hostname" {
  description = "The hostname of the VM-series instance."
  default     = null
  type        = string
}

variable "panorama_server" {
  description = "The FQDN or IP address of the primary Panorama server."
  default     = null
  type        = string
}

variable "panorama_server2" {
  description = "The FQDN or IP address of the secondary Panorama server."
  default     = null
  type        = string
}

variable "tplname" {
  description = "The Panorama template stack name."
  default     = null
  type        = string
}

variable "dgname" {
  description = "The Panorama device group name."
  default     = null
  type        = string
}

variable "dns_primary" {
  description = "The IP address of the primary DNS server."
  default     = null
  type        = string
}

variable "dns_secondary" {
  description = "The IP address of the secondary DNS server."
  default     = null
  type        = string
}

variable "vm_auth_key" {
  description = "Virtual machine authentication key."
  default     = null
  type        = string
}

variable "op_command_modes" {
  description = "Set jumbo-frame and/or mgmt-interface-swap."
  default     = null
  type        = string
}

variable "plugin_op_commands" {
  description = "Set plugin-op-commands."
  default     = null
  type        = string
}

variable "dhcp_send_hostname" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall sends its hostname to the DHCP server."
  default     = "yes"
  type        = string
  validation {
    condition     = contains(["yes", "no"], var.dhcp_send_hostname)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_send_hostname."
  }
}

variable "dhcp_send_client_id" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall sends its client ID to the DHCP server."
  default     = "yes"
  type        = string
  validation {
    condition     = contains(["yes", "no"], var.dhcp_send_client_id)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_send_client_id."
  }
}

variable "dhcp_accept_server_hostname" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall accepts its hostname from the DHCP server."
  default     = "yes"
  type        = string
  validation {
    condition     = contains(["yes", "no"], var.dhcp_accept_server_hostname)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_accept_server_hostname."
  }
}

variable "dhcp_accept_server_domain" {
  description = "The DHCP server determines a value of yes or no. If yes, the firewall accepts its DNS server from the DHCP server."
  default     = "yes"
  type        = string
  validation {
    condition     = contains(["yes", "no"], var.dhcp_accept_server_domain)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_accept_server_domain."
  }
}

variable "create_bucket" {
  description = "If true, a new bucket will be created. When false, name of existing bucket to use has to be provided in `bucket_name` variable."
  default     = true
  type        = bool
}

variable "bucket_name" {
  description = "Name of a bucket to reuse or create (depending on `create_bucket` value). In the latter case - if empty, the name will be auto-generated."
  default     = ""
  type        = string
}
