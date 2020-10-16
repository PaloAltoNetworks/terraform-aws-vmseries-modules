region = "us-east-1"

prefix_name_tag = "vpc-all-options-"   // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Group       = "SecOps"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

vpc = {  // Module only designed for a single VPC. Set all params here. If existing = true, specify the name tag of existing VPC
  vmseries_vpc = {
    existing              = false
    name                  = "my-vpc"
    cidr_block            = "10.100.0.0/16"
    secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]
    instance_tenancy      = "default"
    enable_dns_support    = true
    enable_dns_hostname   = true
    igw                   = true
  }
}

subnets = {
  mgmt-1a       = { existing = false, name = "mgmt-1a", cidr = "10.100.0.0/25", az = "us-east-1a", rt = "mgmt" }   // For brownfield, set existing = true with name tag of existing subnet
  public-1a     = { name = "public-1a", cidr = "10.100.1.0/25", az = "us-east-1a", rt = "vdss-outside" }  
  inside-1a     = { name = "inside-1a", cidr = "10.100.2.0/25", az = "us-east-1a", rt = "tgw-prod-return" }
  tgw-attach-1a = { name = "tgw-attach-1a", cidr = "10.100.3.0/25", az = "us-east-1a", rt = "tgw-prod-attach" }
  lambda-1a     = { name = "lambda-1a", cidr = "10.100.4.0/25", az = "us-east-1a", rt = "lambda" }

  mgmt-1b       = { name = "mgmt-1b", cidr = "10.100.0.128/25", az = "us-east-1b", rt = "mgmt" }
  public-1b     = { name = "public-1b", cidr = "10.100.1.128/25", az = "us-east-1b", rt = "vdss-outside" }
  inside-1b     = { name = "inside-1b", cidr = "10.100.2.128/25", az = "us-east-1b", rt = "tgw-prod-return" }
  tgw-attach-1b = { name = "tgw-attach-1b", cidr = "10.100.3.128/25", az = "us-east-1b", rt = "tgw-prod-attach" }
  lambda-1b     = { name = "lambbda-1b", cidr = "10.100.4.128/25", az = "us-east-1b", rt = "lambda" }
}
