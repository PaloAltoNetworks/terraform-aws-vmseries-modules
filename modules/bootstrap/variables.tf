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

variable "bootstrap_options" {
  description = <<-EOF
  Object define bootstrap options used in the init-cfg.txt file.

  There are available bootstrap parameters:
  - `hostname`                    - (`string`, required) The hostname of the VM-series instance.
  - `panorama_server`             - (`string`, required) The FQDN or IP address of the primary Panorama server.
  - `panorama_server2`            - (`string`, required) The FQDN or IP address of the secondary Panorama server.
  - `tplname`                     - (`string`, required) The Panorama template stack name.
  - `dgname`                      - (`string`, required) The Panorama device group name.
  - `dns_primary`                 - (`string`, required) The IP address of the primary DNS server.
  - `dns_secondary`               - (`string`, required) The IP address of the secondary DNS server.
  - `auth_key`                    - (`string`, required) VM-Series authentication key generated via plugin sw_fw_license.
  - `vm_auth_key`                 - (`string`, required) VM-Series authentication key generated on Panorama.
  - `op_command_modes`            - (`string`, required) Set jumbo-frame and/or mgmt-interface-swap.
  - `plugin_op_commands`          - (`string`, required) Set plugin-op-commands.
  - `dhcp_send_hostname`          - (`string`, required) The DHCP server determines a value of yes or no. If yes, the firewall sends its hostname to the DHCP server.
  - `dhcp_send_client_id`         - (`string`, required) The DHCP server determines a value of yes or no. If yes, the firewall sends its client ID to the DHCP server.
  - `dhcp_accept_server_hostname` - (`string`, required) The DHCP server determines a value of yes or no. If yes, the firewall accepts its hostname from the DHCP server.
  - `dhcp_accept_server_domain`   - (`string`, required) The DHCP server determines a value of yes or no. If yes, the firewall accepts its DNS server from the DHCP server.
  EOF
  default = {
    hostname                    = null
    panorama_server             = null
    panorama_server2            = null
    tplname                     = null
    dgname                      = null
    dns_primary                 = null
    dns_secondary               = null
    auth_key                    = null
    vm_auth_key                 = null
    op_command_modes            = null
    plugin_op_commands          = null
    dhcp_send_hostname          = "yes"
    dhcp_send_client_id         = "yes"
    dhcp_accept_server_hostname = "yes"
    dhcp_accept_server_domain   = "yes"
  }
  type = object({
    hostname                    = string
    panorama_server             = string
    panorama_server2            = string
    tplname                     = string
    dgname                      = string
    dns_primary                 = string
    dns_secondary               = string
    auth_key                    = string
    vm_auth_key                 = string
    op_command_modes            = string
    plugin_op_commands          = string
    dhcp_send_hostname          = string
    dhcp_send_client_id         = string
    dhcp_accept_server_hostname = string
    dhcp_accept_server_domain   = string
  })
  validation {
    condition     = contains(["yes", "no"], var.bootstrap_options.dhcp_send_hostname)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_send_hostname."
  }
  validation {
    condition     = contains(["yes", "no"], var.bootstrap_options.dhcp_send_client_id)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_send_client_id."
  }
  validation {
    condition     = contains(["yes", "no"], var.bootstrap_options.dhcp_accept_server_hostname)
    error_message = "The DHCP server determines a value of yes or no for variable dhcp_accept_server_hostname."
  }
  validation {
    condition     = contains(["yes", "no"], var.bootstrap_options.dhcp_accept_server_domain)
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
