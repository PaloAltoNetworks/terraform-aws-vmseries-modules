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
  value       = aws_iam_instance_profile.this.name
  description = "Name of created IAM instance profile."
}

output "iam_role_name" {
  value       = local.iam_role_name
  description = "Name of created or used IAM role"
}

output "iam_role_arn" {
  value       = local.aws_iam_role.arn
  description = "ARN of created or used IAM role"
}