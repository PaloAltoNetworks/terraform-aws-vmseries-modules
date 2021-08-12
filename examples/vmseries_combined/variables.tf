variable "prefix_name_tag" {}
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}
variable "global_tags" {}
variable "security_vpc_name" {}
variable "security_vpc_cidr" {}
variable "security_vpc_subnets" {}
variable "security_vpc_security_groups" {}
variable "firewalls" {}
variable "interfaces" {}
variable "ssh_key_name" {}
variable "summary_cidr_behind_tgw" {}
variable "summary_cidr_behind_gwlbe_outbound" {}
variable "nat_gateway_name" {}
variable "gwlb_name" {}
variable "gwlb_endpoint_set_eastwest_name" {}
variable "gwlb_endpoint_set_outbound_name" {}
variable "transit_gateway_name" {}
variable "transit_gateway_asn" {}
variable "security_transit_gateway_attachment" {}
variable "app1_vpc_name" {}
variable "app1_vpc_cidr" {}
variable "app1_vpc_subnets" {}
variable "app1_vpc_security_groups" {}
variable "existing_gwlb_name" {}
variable "gwlb_endpoint_set_app1_name" {}
variable "app1_transit_gateway_attachment_name" {}

##### AWS Provider Authentication and Attributes #####
variable "region" {}

variable "aws_access_key" {
  description = "See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details."
  default     = null
  type        = string
}

variable "aws_secret_key" {
  description = "See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details."
  default     = null
  type        = string
}

variable "aws_shared_credentials_file" {
  description = "Example: \"/Users/tf_user/.aws/creds\". See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details."
  default     = null
  type        = string
}

variable "aws_profile" {
  description = "Which profile name to use from within the `aws_shared_credentials_file`. Example: \"myprofile\". See the [`aws` provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#static-credentials) for details."
  default     = null
  type        = string
}

variable "aws_assume_role" {
  description = <<-EOF
  Example:

  ```
  aws_assume_role = {
    role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
    session_name = "SESSION_NAME"
    external_id  = "EXTERNAL_ID"
  }
  ```
  EOF
  default     = null
  type        = map(string)
}
