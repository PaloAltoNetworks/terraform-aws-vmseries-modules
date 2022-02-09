variable "name" {
  description = "Name of the VM-Series instance."
  default     = null
  type        = string
}

# VM-Series version setup
variable "vmseries_ami_id" {
  description = <<-EOF
  Specific AMI ID to use for VM-Series instance.
  If `null` (the default), `vmseries_version` and `vmseries_product_code` vars are used to determine a public image to use.
  EOF
  default     = null
  type        = string
}

variable "vmseries_version" {
  description = <<-EOF
  VM-Series Firewall version to deploy.
  To list all available VM-Series versions, run the command provided below. 
  Please have in mind that the `product-code` may need to be updated - check the `vmseries_product_code` variable for more information.
  ```
  aws ec2 describe-images --region us-west-1 --filters "Name=product-code,Values=6njl1pau431dv1qxipg63mvah" "Name=name,Values=PA-VM-AWS*" --output json --query "Images[].Description" \| grep -o 'PA-VM-AWS-.*' \| sort
  ```
  EOF
  default     = "10.0.8-h8"
  type        = string
}

variable "vmseries_product_code" {
  description = <<-EOF
  Product code corresponding to a chosen VM-Series license type model - by default - BYOL. 
  To check the available license type models and their codes, please refer to the
  [VM-Series documentation](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/obtain-the-ami/get-amazon-machine-image-ids.html)
  EOF
  default     = "6njl1pau431dv1qxipg63mvah"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile."
  default     = null
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  default     = "m5.xlarge"
  type        = string
}

variable "ebs_encrypted" {
  description = "Whether to enable EBS encryption on volumes."
  default     = false
  type        = bool
}

variable "ebs_kms_key_id" {
  description = "The ARN for the KMS key to use for volume encryption."
  default     = null
  type        = string
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances."
  default     = ""
  type        = string
}

variable "interfaces" {
  description = <<-EOF
  List of the network interface specifications.
  By default, the first interface maps to the management interface on the firewall, which does not participate in data filtering. The remaining ones are the dataplane interfaces.
  If "mgmt-interface-swap" bootstrap option is enabled, first interface maps to a dataplane interface and the second interface maps to the firewall management interface.
  Available options:
  - `name`               = (Required|string) Name tag for the ENI.
  - `subnet_id`          = (Required|string) Subnet ID to create the ENI in.
  - `description`        = (Optional|string) A descriptive name for the ENI.
  - `create_public_ip`   = (Optional|bool) Whether to create a public IP for the ENI. Defaults to false.
  - `eip_allocation_id`  = (Optional|string) Associate an existing EIP to the ENI.
  - `private_ips`        = (Optional|list) List of private IPs to assign to the ENI. If not set, dynamic allocation is used.
  - `public_ipv4_pool`   = (Optional|string) EC2 IPv4 address pool identifier. 
  - `source_dest_check`  = (Optional|bool) Whether to enable source destination checking for the ENI. Defaults to false.
  - `security_group_ids` = (Optional|list) A list of Security Group IDs to assign to this interface. Defaults to null.
  
  Example:
  ```
  interfaces = [
    {
      name               = "mgmt"
      subnet_id          = aws_subnet.mgmt.id
      create_public_ip   = true
      source_dest_check  = true
      security_group_ids = ["sg-123456"]
    },
    {
      name             = "public"
      subnet_id        = aws_subnet.public.id
      create_public_ip = true
    },
    {
      name      = "private"
      subnet_id = aws_subnet.private.id
    },
  ]
  ```
  EOF
  default     = []
  # For now it's not possible to have a more strict definition of variable type, optional
  # object attributes are still experimental
  type = list(any)
}

variable "bootstrap_options" {
  description = <<-EOF
  VM-Series bootstrap options to provide using instance user data. Contents determine type of bootstap method to use.
  If empty (the default), bootstrap process is not triggered at all.
  For more information on available methods, please refer to VM-Series documentation for specific version.
  For 10.0 docs are available [here](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/bootstrap-the-vm-series-firewall.html).
  EOF
  default     = ""
  type        = string
}

variable "tags" {
  description = "Map of additional tags to apply to all resources."
  default     = {}
  type        = map(any)
}
