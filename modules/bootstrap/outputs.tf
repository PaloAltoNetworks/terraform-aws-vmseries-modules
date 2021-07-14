output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "AWS identifier of the created bucket."
}

output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of the created bucket."
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.this.bucket_domain_name
  description = "Global domain name of the created bucket."
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "Regional domain name of the created bucket."
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.this.name
  description = "Name of created IAM instance profile."
}
