############################################################
# Provide maps of existing subnet and security group name -> ID
# related to launching Panorama instance
# These will typically be the outputs of other modules
# But can be defined manually, or retreived from data
# lookup and passed into module.
############################################################

locals {
  subnets_map = {
    "mgmt" = "subnet-0b67c0660aae33e2a"
  }

  security_groups_map = {
    "sg1" = "sg-0f4bf202f60c9a159"
  }
}

module "panorama" {
  source              = "../../"
  panorama_version    = var.panorama_version
  global_tags         = var.global_tags
  panoramas           = var.panoramas
  subnets_map         = local.subnets_map
  security_groups_map = local.security_groups_map
}
