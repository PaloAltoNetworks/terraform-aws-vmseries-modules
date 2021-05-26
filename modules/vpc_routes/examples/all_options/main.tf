############################################################
# Create Maps of resource name -> ID Mappings to pass to module
############################################################


## Example of creating Route Table Name -> ID map from data lookup based on Name Tag
data "aws_route_table" "this" {
  for_each = {
    for route in var.vpc_routes : route.route_table => route...
  }
  tags = {
    Name = "${var.prefix_name_tag}${each.key}"
  }
}

locals {
  route_table_ids = {
    for k, route_table in data.aws_route_table.this :
    k => route_table.id
  }
}

## Example of creating Internet Gateway Name -> ID map from data lookup based on Name Tag
data "aws_internet_gateway" "this" { # TODO: fix Error: Your query returned no results. (TERRAM-117)
  for_each = {
    for route in var.vpc_routes : route.next_hop_name => route...
    if lookup(route, "next_hop_type", null) == "internet_gateway" ? true : false
  }
  tags = {
    Name = "${var.prefix_name_tag}${each.key}"
  }
}

locals {
  internet_gateway_ids = {
    for k, igw in data.aws_internet_gateway.this :
    k => igw.id
  }
}

## Example of creating Internet Gateway Name -> ID map from data lookup based on Name Tag
data "aws_vpn_gateway" "this" {
  for_each = {
    for route in var.vpc_routes : route.next_hop_name => route...
    if lookup(route, "next_hop_type", null) == "vpn_gateway" ? true : false
  }
  tags = {
    Name = "${var.prefix_name_tag}${each.key}"
  }
}

locals {
  vpn_gateway_ids = {
    for k, vgw in data.aws_vpn_gateway.this :
    k => vgw.id
  }
}


// TODO: Add example of referencing direct reference from VPC module, remote state output, and manually defined map values


output "route_tables" {
  value = local.route_table_ids
}

output "igws" {
  value = local.internet_gateway_ids
}


############################################################
# Call Route module
############################################################

module "all_options" {
  source            = "../../"
  global_tags       = var.global_tags
  prefix_name_tag   = var.prefix_name_tag
  vpc_routes        = var.vpc_routes
  vpc_route_tables  = local.route_table_ids
  internet_gateways = local.internet_gateway_ids
  vpn_gateways      = local.vpn_gateway_ids
}
