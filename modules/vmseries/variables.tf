variable "name" {
  description = "Name of the VM-Series virtual machine."
  type        = string
}

variable "panos_version" {
  description = "PAN-OS version of the firewall to deploy."
  type        = string
  default     = "9.1.9"
}

variable "fw_product" {
  description = "Type of firewall product: one of 'byol', 'bundle-1', 'bundle-2'."
  default     = "byol"
}

variable "fw_product_map" {
  description = "Firewall product codes."
  type        = map(string)

  default = {
    byol     = "6njl1pau431dv1qxipg63mvah"
    bundle-1 = "6kxdw3bbmdeda3o6i1ggqt4km"
    bundle-2 = "806j2of0qy5osgjjixq9gqc6g"
  }
}

variable "custom_ami_id" {
  description = "Custom AMI id to use instead of using an AMI published in the Marketplace."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for firewall."
  type        = string
  default     = "m5.xlarge"
}

variable "ssh_key_name" {
  description = "AWS EC2 key pair name."
  type        = string
}

variable "iam_instance_profile" {
  description = "Firewall instance IAM profile."
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data to provide when launching the instance."
  type        = string
  default     = null
}

variable "interfaces" {
  description = <<-EOF
  List of the network interface specifications.
  The first should be the Management network interface, which does not participate in data filtering.
  The remaining ones are the dataplane interfaces.
  - `name`: (Required|string) Name tag for the ENI.
  - `description`: (Optional|string) A descriptive name for the ENI.
  - `subnet_id`: (Required|string) Subnet ID to create the ENI in.
  - `private_ip_address`: (Optional|string) Private IP to assign to the ENI. If not set, dynamic allocation is used.
  - `eip_allocation_id`: (Optional|string) Associate an existing EIP to the ENI.
  - `create_public_ip`: (Optional|bool) Whether to create a public IP for the ENI. Default false.
  - `public_ipv4_pool`: (Optional|string) EC2 IPv4 address pool identifier. 
  - `source_dest_check`: (Optional|bool) Whether to enable source destination checking for the ENI. Default false.
  - `security_groups`: (Optional|list) A list of Security Group IDs to assign to this interface. Default null.
  Example:
  ```
  interfaces =[
    {
      name: "mgmt"
      subnet_id: subnet-00000000000000001
      create_public_ip: true
    },
    {
      name: "public"
      subnet_id: subnet-00000000000000002
      create_public_ip: true
      source_dest_check: false
    },
    {
      name: "private"
      subnet_id: subnet-00000000000000003
      source_dest_check: false
    },
  ]
  ```
  EOF
}

variable "tags" {
  description = "A map of tags to be associated with the resources created."
  default     = {}
  type        = map(any)
}