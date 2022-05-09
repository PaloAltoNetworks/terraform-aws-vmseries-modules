# General
region          = "us-east-1"
prefix_name_tag = "example-"
global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
}

# Security VPC
security_vpc_name = "security-vpc"
security_vpc_cidr = "10.100.0.0/16"

# Security groups
security_vpc_security_groups = {
  vmseries_data = {
    name = "vmseries_data"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      geneve = {
        description = "Permit GENEVE to GWLB subnets"
        type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
        cidr_blocks = ["10.100.5.0/24", "10.100.69.0/24"]
      }
      health_probe = {
        description = "Permit Port 80 Health Probe to GWLB subnets"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["10.100.5.0/24", "10.100.69.0/24"]
      }
    }
  }
  vmseries_mgmt = {
    name = "vmseries_mgmt"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: update here
      }
      panorama_ssh = {
        description = "Permit Panorama SSH (Optional)"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
      panorama_mgmt = {
        description = "Permit Panorama Management"
        type        = "ingress", from_port = "3978", to_port = "3978", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
      panorama_log = {
        description = "Permit Panorama Logging"
        type        = "ingress", from_port = "28443", to_port = "28443", protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
      }
    }
  }
}

# Security VPC Subnets
security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"  = { az = "us-east-1a", set = "mgmt" }
  "10.100.64.0/24" = { az = "us-east-1b", set = "mgmt" }
  "10.100.1.0/24"  = { az = "us-east-1a", set = "data1" }
  "10.100.65.0/24" = { az = "us-east-1b", set = "data1" }
  "10.100.3.0/24"  = { az = "us-east-1a", set = "tgw_attach" }
  "10.100.67.0/24" = { az = "us-east-1b", set = "tgw_attach" }
  "10.100.4.0/24"  = { az = "us-east-1a", set = "gwlbe_outbound" }
  "10.100.68.0/24" = { az = "us-east-1b", set = "gwlbe_outbound" }
  "10.100.5.0/24"  = { az = "us-east-1a", set = "gwlb" }
  "10.100.69.0/24" = { az = "us-east-1b", set = "gwlb" }
  "10.100.11.0/24" = { az = "us-east-1a", set = "natgw" }
  "10.100.75.0/24" = { az = "us-east-1b", set = "natgw" }
}

# Gateway Load Balancer
gwlb_name                       = "security-gwlb"
gwlb_endpoint_set_outbound_name = "outbound-gwlb-endpoint"

### NAT gateway
nat_gateway_name = "natgw"

# VM-Series
fw_instance_type = "m5.xlarge"
ami_id           = "ami-0db881e84b17f6b39"
# fw_license_type  = "byol"
# fw_version       = "10.0.8-h8"
create_ssh_key = false
ssh_key_name   = "Blackstone" // CHANGE_ME!

interfaces = [
  # vmseries01
  {
    name                          = "vmseries01_data"
    source_dest_check             = false
    subnet_name                   = "data1a"
    security_group                = "vmseries_data"
    private_ip_address_allocation = "dynamic"
  },
  {
    name              = "vmseries01_mgmt"
    source_dest_check = true
    subnet_name       = "mgmta"
    security_group    = "vmseries_mgmt"
    private_ips       = ["10.144.50.10"]
    eip               = "vmseries01_mgmt"
    eip_name          = "vmseries01_mgmt"
  },
  {
    name                          = "vmseries01_untrust"
    source_dest_check             = false
    subnet_name                   = "untrusta"
    security_group                = "vmseries_untrust"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries01_untrust"
    eip_name                      = "vmseries01_untrust"
  },
  # vmseries02
  {
    name                          = "vmseries02_data"
    source_dest_check             = false
    subnet_name                   = "data1b"
    security_group                = "vmseries_data"
    private_ip_address_allocation = "dynamic"
  },
  {
    name              = "vmseries02_mgmt"
    source_dest_check = true
    subnet_name       = "mgmtb"
    security_group    = "vmseries_mgmt"
    private_ips       = ["10.144.51.10"]
    eip               = "vmseries02_mgmt"
    eip_name          = "vmseries02_mgmt"
  },
  {
    name                          = "vmseries02_untrust"
    source_dest_check             = false
    subnet_name                   = "untrustb"
    security_group                = "vmseries_untrust"
    private_ip_address_allocation = "dynamic"
    eip                           = "vmseries02_untrust"
    eip_name                      = "vmseries02_untrust"
  },
]

# Security VPC routes ###
security_vpc_routes_outbound_source_cidrs = [ # outbound traffic return after inspection
  "10.0.0.0/8",
]

security_vpc_routes_outbound_destin_cidrs = [ # outbound traffic incoming for inspection from TGW
  "0.0.0.0/0",
]

security_vpc_mgmt_routes_to_tgw = [
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16"
]
