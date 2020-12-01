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
 * }
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
 * }
 *
 *subnets = {
 *  mgmt-1a       = { existing = false, name = "mgmt-1a", cidr = "10.100.0.0/25", az = "us-east-1a", rt = "mgmt" }            # VM-Series management
 *  public-1a     = { name = "public-1a", cidr = "10.100.1.0/25", az = "us-east-1a", rt = "vdss-outside" }    # interface in public subnet for internet
 *  mgmt-1b       = { name = "mgmt-1b", cidr = "10.100.0.128/25", az = "us-east-1b", rt = "mgmt" }            # VM-Series management
 *  public-1b     = { name = "public-1b", cidr = "10.100.1.128/25", az = "us-east-1b", rt = "vdss-outside" }    # interface in public subnet for internet
 * }
 *
 * ```
 * 
 */

################
# VPC Routes
################

# Create route conditional on gateway type variable (igw, tgw, natgw, eni)

resource "aws_route" "internet_gateway" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "internet_gateway"
  }
  route_table_id         = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block = each.value.prefix
  gateway_id             = var.internet_gateways[each.value.next_hop_name]
}

resource "aws_route" "vpn_gateway" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "vpn_gateway"
  }
  route_table_id         = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block = each.value.prefix
  gateway_id             = var.vpn_gateways[each.value.next_hop_name]
}

resource "aws_route" "nat_gateway" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "nat_gateway"
  }
  route_table_id         = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block = each.value.prefix
  nat_gateway_id         = var.nat_gateways[each.value.next_hop_name]
}

resource "aws_route" "network_interface" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "interface"
  }
  route_table_id         = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block = each.value.prefix
  network_interface_id   = var.interfaces[each.value.next_hop_name]
}

resource "aws_route" "transit_gateway" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "transit_gateway"
  }
  route_table_id         = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block = each.value.prefix
  transit_gateway_id     = var.transit_gateways[each.value.next_hop_name]
}

resource "aws_route" "vpc_peer" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "vpc_peer"
  }
  route_table_id            = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block    = each.value.prefix
  vpc_peering_connection_id = var.vpc_peers[each.value.next_hop_name]
}

resource "aws_route" "vpc_endpoint" {
  for_each = {
    for k, v in var.vpc_routes : k => v
    if v.next_hop_type == "vpc_endpoint"
  }
  route_table_id         = var.vpc_route_tables[each.value.route_table]
  destination_cidr_block = each.value.prefix
  vpc_endpoint_id        = var.vpc_endpoints[each.value.next_hop_name]
} 