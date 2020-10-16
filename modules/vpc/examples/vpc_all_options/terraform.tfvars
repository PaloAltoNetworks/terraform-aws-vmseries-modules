region = "us-east-1"

prefix_name_tag = "vpc-all-options-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Group       = "SecOps"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

vpc = { // Module only designed for a single VPC. Set all params here. If existing = true, specify the Name tag of existing VPC
  vmseries_vpc = {
    existing              = false
    name                  = "my-vpc"
    cidr_block            = "10.100.0.0/16"
    secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]
    instance_tenancy      = "default"
    enable_dns_support    = true
    enable_dns_hostname   = true
    igw                   = true
    local_tags = {"vpc_tag" = "whatever"}
  }
}

vpc_route_tables = {
  mgmt             = { name = "mgmt", vgw_propagation = "vmseries_vgw"  }
  public           = { name = "public"  }
  tgw-return       = { name = "tgw-return" }
  tgw-attach       = { name = "tgw-attach" }
  lambda           = { name = "lambda" }
  igw-ingress      = { name = "igw-ingress", igw_association = "vmseries_vpc" }
  vgw-ingress      = { name = "vgw-ingress", vgw_assocaiation = "vmseries_vgw" }
}

subnets = {
# mgmt-1a       = { existing = true, name = "mgmt-1a" } // For brownfield, set existing = true with name tag of existing subnet
  mgmt-1a       = { name = "mgmt-1a", cidr = "10.100.0.0/25", az = "us-east-1a", rt = "mgmt", local_tags = {"subnet_tag" = "whatever"}}
  public-1a     = { name = "public-1a", cidr = "10.100.1.0/25", az = "us-east-1a", rt = "public" }
  inside-1a     = { name = "inside-1a", cidr = "10.100.2.0/25", az = "us-east-1a", rt = "tgw-return" }
  tgw-attach-1a = { name = "tgw-attach-1a", cidr = "10.100.3.0/25", az = "us-east-1a", rt = "tgw-attach" }
  lambda-1a     = { name = "lambda-1a", cidr = "10.100.4.0/25", az = "us-east-1a", rt = "lambda" }

  mgmt-1b       = { name = "mgmt-1b", cidr = "10.100.0.128/25", az = "us-east-1b", rt = "mgmt" }
  public-1b     = { name = "public-1b", cidr = "10.100.1.128/25", az = "us-east-1b", rt = "public" }
  inside-1b     = { name = "inside-1b", cidr = "10.100.2.128/25", az = "us-east-1b", rt = "tgw-return" }
  tgw-attach-1b = { name = "tgw-attach-1b", cidr = "10.100.3.128/25", az = "us-east-1b", rt = "tgw-attach" }
  lambda-1b     = { name = "lambbda-1b", cidr = "10.100.4.128/25", az = "us-east-1b", rt = "lambda" }
}

vgws = {
  vmseries_vgw = {
    name = "vmseries_vgw"
    vpc_attached = true
    amazon_side_asn = "7224"
    # dx_gateway_id = "3d3388c7-eab9-408b-a33d-796dcfa231d4"
    local_tags = {"vgw_tag" = "whatever"}
  }
  detached_vgw = {
    name = "detached_vgw"
    vpc_attached = false
    amazon_side_asn = "65200"
  }
}