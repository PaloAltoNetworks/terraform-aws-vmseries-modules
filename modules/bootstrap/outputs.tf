output "bucket_id" {
  value       = local.aws_s3_bucket.id
  description = "AWS identifier of the bucket."
}

output "bucket_name" {
  value       = local.aws_s3_bucket.bucket
  description = "Name of the bucket."
}

output "bucket_domain_name" {
  value       = local.aws_s3_bucket.bucket_domain_name
  description = "Global domain name of the bucket."
}

output "bucket_regional_domain_name" {
  value       = local.aws_s3_bucket.bucket_regional_domain_name
  description = "Regional domain name of the bucket."
}

output "instance_profile_name" {
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : null
  description = "Name of created IAM instance profile."
}
