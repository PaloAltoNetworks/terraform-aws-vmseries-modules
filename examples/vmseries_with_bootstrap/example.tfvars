### GLOBAL
region          = "us-east-1"
prefix_name_tag = "foo-bar-" // Used for Name Tags of all created resources. Can be empty.

global_tags = {
  Foo        = "Bar"
  Managed-by = "Terraform"
}

### VPC
vpc_cidr_block = "172.22.0.0/16"

security_groups = {
  vmseries-mgmt = {
    name = "vmseries-mgmt"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https-inbound = {
        description = "Permit HTTPS for VM-Series Management"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh-inbound = {
        description = "Permit SSH for VM-Series Management from known public IPs"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}

### SUBNET_SET
subnets = {
  "172.22.0.0/24" = { az = "us-east-1a", set = "mgmt-1" }
}

### VMSERIES
fw_instance_type = "m5.xlarge"
fw_license_type  = "byol"
fw_version       = "10.0.6"
ssh_key_name     = "kbechler"

interfaces = [
  {
    name                          = "vmseries-mgmt"
    source_dest_check             = true
    subnet_name                   = "mgmt-1a"
    security_group                = "vmseries-mgmt"
    private_ip_address_allocation = "dynamic"
    eip_name                      = true
  },
]

firewalls = [
  {
    name              = "vmseries"
    fw_tags           = {}
    bootstrap_options = {}
    interfaces = [{ # Only assign default interface here to avoid instance recreation when later updating interfaces
      name  = "vmseries-mgmt"
      index = "0"
    }]
  },
]
