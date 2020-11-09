############################################################
# Provide maps of existing subnet and security group name -> ID
# related to launching Panorama instance
# These will typically be the outputs of other modules
# But can be defined manually, or retreived from data
# lookup and passed into module.
############################################################

locals {
  subnets_map = {
    "foo" = "subnet-123456789012"
    "bar" = "subnet-123456789012"
    "baz" = "subnet-123456789012"
  }
  security_groups_map = {
    "foo" = "sg-123456789012"
    "bar" = "sg-123456789012"
  }
}

module "panorama" {
  source              = "../../"
  global_tags         = var.global_tags
  panoramas           = var.panoramas
  prefix_name_tag     = var.prefix_name_tag
  subnets_map         = local.subnets_map
  security_groups_map = local.security_groups_map
}