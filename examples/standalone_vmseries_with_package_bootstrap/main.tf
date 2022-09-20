module "bootstrap" {
  source                 = "../../modules/bootstrap"
  prefix                 = var.name_prefix
  global_tags            = var.global_tags
  create_iam_role_policy = var.create_iam_role_policy
  iam_role_name          = var.iam_role_name
}