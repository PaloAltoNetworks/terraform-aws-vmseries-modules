variable "prefix_name_tag" {}
variable "global_tags" {}
variable "security_vpc_name" {}
variable "security_vpc_cidr" {}
variable "security_vpc_subnets" {}
variable "security_vpc_security_groups" {}
variable "nat_gateway_name" {}
variable "gwlb_name" {}
variable "gwlb_endpoint_set_eastwest_name" {}
variable "gwlb_endpoint_set_outbound_name" {}
variable "transit_gateway_name" {}
variable "transit_gateway_asn" {}
variable "security_transit_gateway_attachment_name" {}
variable "firewalls" {}
variable "interfaces" {}
variable "fw_instance_type" {}
variable "fw_license_type" {}
variable "fw_version" {}

##### Security VPC Routes #####

variable "security_vpc_routes_outbound_source_cidrs" {
  description = "From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing outside. Used for return traffic routes post-inspection. A list of strings, for example `[\"10.0.0.0/8\"]`."
  type        = list(string)
}

variable "security_vpc_routes_outbound_destin_cidrs" {
  description = "From the perspective of Security VPC, the destination addresses of packets coming from TGW and flowing outside. A list of strings, for example `[\"0.0.0.0/0\"]`."
  type        = list(string)
}

variable "security_vpc_mgmt_routes_to_tgw" {
  description = "The eastwest inspection of traffic heading to VM-Series mgmt is not possible. Due to AWS own limitations, anything from tgw destined for mgmt could *not* possibly override LocalVPC route. Henceforth no mgmt routes go back to gwlbe_eastwest."
  type        = list(string)
}

variable "security_vpc_routes_eastwest_cidrs" {
  description = "From the perspective of Security VPC, the source addresses of packets coming from TGW and flowing back to TGW. A list of strings, for example `[\"10.0.0.0/8\"]`."
  type        = list(string)
}

##### Spoke VPC app1 #####

variable "app1_vpc_name" {}
variable "app1_vpc_cidr" {}
variable "app1_vpc_subnets" {}
variable "app1_vpc_security_groups" {}
variable "existing_gwlb_name" {}
variable "app1_gwlb_endpoint_set_name" {}
variable "app1_transit_gateway_attachment_name" {}

##### SSH Key Uploaded to AWS #####

variable "ssh_key_name" {
  default = "sshkey"
}

variable "create_ssh_key" {
  default = true
}

variable "ssh_public_key_file_path" {
}

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
