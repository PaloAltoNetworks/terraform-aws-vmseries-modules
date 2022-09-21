variable "region" {
  description = "AWS region to use for the created resources."
  default     = "us-east-1"
  type        = string
}

variable "switchme" {
  description = "The true/false switch for testing the modifiability. Initial runs should use `true`, then at some point one or more consecutive runs should use `false` instead."
  type        = bool
}

variable "create_iam_role_policy" {
  description = "If true, a new IAM role with policy will be created. When false, name of existing IAM role and policy to use has to be provided in `iam_role_name` and `iam_policy_name` variable."
  default     = true
}

module "bootstrap" {
  source                 = "../../modules/bootstrap"
  prefix                 = "a"
  global_tags            = var.switchme ? {} : { switchme = var.switchme }
  create_iam_role_policy = var.create_iam_role_policy
}

output "bucket_name_correct" {
  value = (substr(module.bootstrap.bucket_name, 0, 1) == "a")
}

output "instance_profile_name_correct" {
  value = (substr(module.bootstrap.instance_profile_name, 0, 1) == "a")
}

output "bucket_domain_name" {
  value = module.bootstrap.bucket_domain_name
}

output "iam_role_name" {
  value = module.bootstrap.iam_role_name
}

output "iam_role_arn" {
  value = module.bootstrap.iam_role_arn
}