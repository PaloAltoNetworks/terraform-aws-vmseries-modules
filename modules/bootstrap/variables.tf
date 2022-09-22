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
  default     = ""
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
  default     = ""
  type        = string
}

variable "panorama-server" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "The FQDN or IP address of the primary Panorama server."
  default     = ""
  type        = string
}

variable "panorama-server2" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "The FQDN or IP address of the secondary Panorama server."
  default     = ""
  type        = string
}

variable "tplname" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "The Panorama template stack name."
  default     = ""
  type        = string
}

variable "dgname" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "The Panorama device group name."
  default     = ""
  type        = string
}

variable "dns-primary" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "The IP address of the primary DNS server."
  default     = ""
  type        = string
}

variable "dns-secondary" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "The IP address of the secondary DNS server."
  default     = ""
  type        = string
}

variable "vm-auth-key" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "Virtual machine authentication key."
  default     = ""
  type        = string
}

variable "op-command-modes" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "Set jumbo-frame and/or mgmt-interface-swap."
  default     = ""
  type        = string
}

variable "plugin-op-commands" { # tflint-ignore: terraform_naming_convention # TODO rename to snake_case
  description = "Set plugin-op-commands."
  default     = ""
  type        = string
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
