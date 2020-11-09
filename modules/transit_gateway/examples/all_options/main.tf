############################################################
# Provide maps of existing VPC and subnet name -> ID
# for creating TGW attachments with this module.
# These will typically be the outputs of other modules
# But can be defined manually, or retreived from data
# lookup and passed into module.
############################################################

locals {
  vpcs = {
    "foo" = "vpc-123456789012"
    "bar" = "vpc-123456789012"
  }
  subnets = {
    "foo" = "subnet-123456789012"
    "bar" = "subnet-123456789012"
    "baz" = "subnet-123456789012"
  }
}

module "transit_gateways" {
  source                          = "../../"
  global_tags                     = var.global_tags
  prefix_name_tag                 = var.prefix_name_tag
  subnets                         = local.subnets
  vpcs                            = local.vpcs
  transit_gateways                = var.transit_gateways
  transit_gateway_vpc_attachments = var.transit_gateway_vpc_attachments
  transit_gateway_peerings        = var.transit_gateway_peerings
}