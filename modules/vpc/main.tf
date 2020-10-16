/**
 * # Base AWS Infrrastructure Resources for VM-Series
 *
 * ## Overview
 * Create VPC, Subnets, Security Groups, Transit Gateways, Route Tables, and other optional resources to support a Palo Alto Networks VM-Series Deployment.
 * 
 * 
 * ### Usage
 * ```
 * provider "aws" {
 *   region = var.region
 * }
 * 
 * module "vpc" {
 *   source     = "git::https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/modules/vpc?ref=v0.1.0"
 *
 * prefix_name_tag = "my-prefix"   // Used for resource name Tags. Leave as empty string if not desired
 *
 * global_tags = {
 *  Environment = "us-east-1"
 *  Group       = "SecOps"
 *  Managed_By  = "Terraform"
 *  Description = "Example Usage"
 *}
 *
 * vpc = {
 *  vmseries_vpc = {
 *   existing              = false
 *    name                  = "vmseries-vpc"
 *    cidr_block            = "10.100.0.0/16"
 *    secondary_cidr_blocks = ["10.200.0.0/16", "10.201.0.0/16"]
 *    instance_tenancy      = "default"
 *    enable_dns_support    = true
 *    enable_dns_hostname   = true
 *    igw                   = true
 *  }
 *}

 *subnets = {
 *  mgmt-1a       = { existing = false, name = "mgmt-1a", cidr = "10.100.0.0/25", az = "us-east-1a", rt = "mgmt" }            # VM-Series management
 *  public-1a     = { name = "public-1a", cidr = "10.100.1.0/25", az = "us-east-1a", rt = "vdss-outside" }    # interface in public subnet for internet
 *  mgmt-1b       = { name = "mgmt-1b", cidr = "10.100.0.128/25", az = "us-east-1b", rt = "mgmt" }            # VM-Series management
 *  public-1b     = { name = "public-1b", cidr = "10.100.1.128/25", az = "us-east-1b", rt = "vdss-outside" }    # interface in public subnet for internet
 *}
 *
 * ```
 * 
 */

terraform {
  required_version = "~> 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}

################
# Locals to combine data source and resource references for optional browfield support
################


####  VPC #### 
locals {
  existing_vpc = {
    for k, vpc in data.aws_vpc.this:
    "vpc_id" => vpc.id 
  }

  new_vpc = {
    for k, vpc in aws_vpc.this:
    "vpc_id" => vpc.id 
  }

  combined_vpc = merge(local.existing_vpc, local.new_vpc)
}

data "aws_vpc" "this" {
  for_each               = {
    for k, vpc in var.vpc : k => vpc
    if lookup(vpc, "existing", null) == true ? true : false
  }
  tags = {
    Name = each.value.name
  }
}

####  Subnets #### 
locals {
  existing_subnets = {
    for k, subnet in data.aws_subnet.this:
    k => subnet.id 
  }

  new_subnets = {
    for k, subnet in aws_subnet.this:
    k => subnet.id 
  }

  combined_subnets = merge(local.existing_subnets, local.new_subnets)
}

data "aws_subnet" "this" {
  for_each               = {
    for k, subnet in var.subnets : k => subnet
    if lookup(subnet, "existing", null) == true ? true : false
  }
  tags = {
    Name = "${var.prefix_name_tag}${each.value.name}"
  }
}

################
# Resource Creation
################

#### Create VPC resources #### 

resource "aws_vpc" "this" {
  for_each               = {
    for k, vpc in var.vpc : k => vpc
    if lookup(vpc, "existing", null) != true ? true : false
  }
  cidr_block = each.value.cidr_block
  tags       = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
  enable_dns_hostnames = lookup(each.value, "enable_dns_hostnames", null)
  enable_dns_support = lookup(each.value, "enable_dns_support", null)
  instance_tenancy = lookup(each.value, "instance_tenancy", null)
}

locals {  // Create new list of optional secondary_cidr_blocks if key exists in var.vpc
  secondary_cidr_blocks = flatten ([
    for vpc in var.vpc : [
        for cidr in toset(vpc.secondary_cidr_blocks) : {
            vpc = vpc.name
            cidr = cidr
        }
    ]
    if lookup(vpc, "secondary_cidr_blocks", null) != null ? true : false
  ])
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each          = { for value in local.secondary_cidr_blocks : "${value.vpc}-${value.cidr}" => value }
  vpc_id           = local.combined_vpc["vpc_id"]
  cidr_block = each.value.cidr
}

#### Create IGW #### 

resource "aws_internet_gateway" "this" {
  for_each               = {
    for k, vpc in var.vpc : k => vpc
    if lookup(vpc, "igw", null) == null ? true : vpc.igw  // Defaults to true if not specified
  }
  vpc_id = local.combined_vpc["vpc_id"]
  tags   = merge({ Name = "${var.prefix_name_tag}igw" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

#### Create Subnets ####

resource "aws_subnet" "this" {
  for_each               = {
    for k, subnet in var.subnets : k => subnet
    if lookup(subnet, "existing", null) != true ? true : false
  }
  cidr_block        = each.value.cidr
  availability_zone = lookup(each.value, "az", null)
  tags              = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
  vpc_id            = local.combined_vpc["vpc_id"]
  depends_on        = [aws_vpc_ipv4_cidr_block_association.this]
}

#### Create and associate Route tables #### 

resource "aws_route_table" "this" {
  for_each = var.vpc_route_tables
  vpc_id   = local.combined_vpc["vpc_id"]
  tags = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_route_table_association" "this" {
  for_each               = {
    for k, subnet in var.subnets : k => subnet
    if lookup(subnet, "existing", null) != true ? true : false
  }
  subnet_id      = local.combined_subnets[each.key]
  route_table_id = aws_route_table.this[each.value.rt].id
}

##########################
# Create VGW
##########################

resource "aws_vpn_gateway" "this" {
  for_each          = var.vgws
  vpc_id            = lookup(each.value, "vpc_attached", null) != false ? local.combined_vpc["vpc_id"] : null // Default is to attach to VPC
  amazon_side_asn   = each.value.amazon_side_asn
  tags              = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

resource "aws_dx_gateway_association" "this" {
  for_each              = { for name, vgw in var.vgws : name => vgw if contains(keys(vgw), "dx_gateway_id")}
  dx_gateway_id         = each.value.dx_gateway_id
  associated_gateway_id = aws_vpn_gateway.this[each.key].id
}

#### Optionally enable VGW Propogation for Route Tables #### 
resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = { for name, rt in var.vpc_route_tables : name => rt if contains(keys(rt), "vgw_propagation")}
  vpn_gateway_id = aws_vpn_gateway.this[each.value.vgw_propagation].id
  route_table_id = aws_route_table.this[each.key].id
}

#### Associate RT to VGW for AWS Ingress Routing #### 

resource "aws_route_table_association" "vgw_ingress" {
  for_each = { for name, rt in var.vpc_route_tables : name => rt if contains(keys(rt), "vgw_association")}
  route_table_id   = aws_route_table.this[each.key].id
  gateway_id = aws_vpn_gateway.this[each.value.vgw_association].id
}

#### Associate RT to IGW for AWS Ingress Routing #### 

resource "aws_route_table_association" "igw_ingress" {
  for_each = { for name, rt in var.vpc_route_tables : name => rt if contains(keys(rt), "igw_association")}
  route_table_id   = aws_route_table.this[each.key].id
  gateway_id = aws_internet_gateway.this[each.value.igw_association].id
}