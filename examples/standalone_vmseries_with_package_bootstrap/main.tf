module "bootstrap" {
  source      = "../../modules/bootstrap"
  prefix      = var.name_prefix
  global_tags = var.global_tags
}