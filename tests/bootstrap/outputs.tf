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
