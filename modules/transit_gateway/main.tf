################
# Locals to combine data source and resource references for optional browfield support
################


#### Transit Gateways #### 
locals {
  existing_transit_gateways = {
    for k, tgw in data.aws_ec2_transit_gateway.this :
    k => tgw.id
  }

  new_transit_gateways = {
    for k, tgw in aws_ec2_transit_gateway.this :
    k => tgw.id
  }

  combined_transit_gateways = merge(local.existing_transit_gateways, local.new_transit_gateways)
}

data "aws_ec2_transit_gateway" "this" {
  for_each = {
    for k, tgw in var.transit_gateways : k => tgw
    if lookup(tgw, "existing", null) == true ? true : false
  }
  filter {
    name   = "tag:Name"
    values = [each.value.name]
  }
}

#### Transit Gateway Route Tables ####  
locals {
  existing_transit_gateway_route_tables = {
    for k, rt in data.aws_ec2_transit_gateway_route_table.this :
    k => rt.id
  }

  new_transit_gateway_route_tables = {
    for k, rt in aws_ec2_transit_gateway_route_table.this :
    k => rt.id
  }

  combined_transit_gateway_route_tables = merge(local.existing_transit_gateway_route_tables, local.new_transit_gateway_route_tables)
}

data "aws_ec2_transit_gateway_route_table" "this" {
  #   for_each = {
  #     for k, tgw in var.transit_gateways : k => tgw
  #     if lookup(tgw, "existing", null) == true ? true : false
  #   }
  for_each = {
    for rt in local.transit_gateway_route_tables : "${rt.tgw}-${rt.rt}" => rt
    if lookup(rt, "existing", null) == true ? true : false
  }
  filter {
    name   = "tag:Name"
    values = [each.value.name]
  }
}

############################################################
# Create TGWs, TGW Route Tables, Attachements
############################################################

resource "aws_ec2_transit_gateway" "this" {
  #for_each = var.transit_gateways
  for_each = {
    for k, tgw in var.transit_gateways : k => tgw
    if lookup(tgw, "existing", null) != true ? true : false
  }
  amazon_side_asn                 = each.value.asn
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags                            = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

################
# Local loop to create maps Route Tables to create for each TGW
################

locals {
  transit_gateway_route_tables = flatten([
    for tgw_key, tgw_value in var.transit_gateways : [
      for rt_key, rt_value in tgw_value.route_tables : {
        tgw      = tgw_key
        rt       = rt_key
        name     = rt_value.name
        existing = lookup(rt_value, "existing", null)
      }
    ]
    if lookup(tgw_value, "route_tables", null) != null ? true : false
  ])
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = { for value in local.transit_gateway_route_tables :
    "${value.tgw}-${value.rt}" => value
    if lookup(value, "existing", null) != true ? true : false
  }
  transit_gateway_id = local.combined_transit_gateways[each.value.tgw]
  tags               = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}


resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.transit_gateway_vpc_attachments
  // TODO - Fix reference for subnet ids to not require index
  #subnet_ids = ["${aws_subnet.this[each.value.subnets[0]].id}", "${aws_subnet.this[each.value.subnets[1]].id}"]
  #subnet_ids                                      = [var.subnets[each.value.subnets]]
  subnet_ids = [
    for subnet in each.value.subnets :
    var.subnets[subnet]
  ]
  vpc_id                                          = var.vpcs[each.value.vpc]
  transit_gateway_id                              = local.combined_transit_gateways[each.value.transit_gateway]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}


resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = var.transit_gateway_vpc_attachments
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = local.combined_transit_gateway_route_tables["${each.value.transit_gateway}-${each.value.transit_gateway_route_table_association}"]
}


##########################
# Resource Shares for TGWs
##########################

# Create Resource Share if 'shared_principals' key is defined
resource "aws_ram_resource_share" "this" {
  for_each                  = { for name, tgw in var.transit_gateways : name => tgw if contains(keys(tgw), "shared_principals") }
  allow_external_principals = true
  name                      = "${var.prefix_name_tag}${each.value.name}"
  tags                      = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
}

# Associate TGW to Share
resource "aws_ram_resource_association" "this" {
  for_each           = { for name, tgw in var.transit_gateways : name => tgw if contains(keys(tgw), "shared_principals") }
  resource_arn       = aws_ec2_transit_gateway.this[each.key].arn
  resource_share_arn = aws_ram_resource_share.this[each.key].arn
}


# Local loop to create list of principal accounts to share each TGW with

locals {
  ram_principals = flatten([
    for tgw_key, tgw_value in var.transit_gateways : [
      for principal in toset(tgw_value.shared_principals) : {
        tgw       = tgw_key
        principal = principal
      }
    ]
    if lookup(tgw_value, "shared_principals", null) != null ? true : false
  ])
}

# Loop through list of accounts to associate with each share
resource "aws_ram_principal_association" "this" {
  for_each           = { for principal in local.ram_principals : "${principal.tgw}-${principal.principal}" => principal }
  principal          = each.value.principal
  resource_share_arn = aws_ram_resource_share.this[each.value.tgw].arn
}


##########################
# Create TGW Cross Region Peering
##########################

// TODO: This needs to be updated to work with new data models

# provider "aws" {
#   alias  = "tgw_peer"
#   region = var.transit_gateway_peer_region
# }

# resource "aws_ec2_transit_gateway_peering_attachment" "this" {
#   for_each                = var.transit_gateway_peerings
#   peer_account_id         = each.value.peer_account_id
#   peer_region             = each.value.peer_region
#   peer_transit_gateway_id = each.value.peer_transit_gateway_id
#   transit_gateway_id      = aws_ec2_transit_gateway.this[each.key].id

#   tags = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
# }

# resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
#   provider                      = aws.tgw_peer
#   for_each                      = var.transit_gateway_peerings
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this[each.key].id

#   tags = merge({ Name = "${var.prefix_name_tag}${each.value.name}" }, var.global_tags, lookup(each.value, "local_tags", {}))
# }

# resource "aws_ec2_transit_gateway_route_table_association" "tgw_peer_local" {
#   for_each                       = var.transit_gateway_peerings
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this[each.key].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.tgw_rt_association].id
# }

# resource "aws_ec2_transit_gateway_route_table_association" "tgw_peer_remote" {
#   provider                       = aws.tgw_peer
#   for_each                       = var.transit_gateway_peerings
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this[each.key].id
#   transit_gateway_route_table_id = each.value.peer_tgw_rt_association
# }