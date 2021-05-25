output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "ID of created bucket."
}

output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of created bucket."
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.this.name
  description = "Name of created IAM instance profile."
}
