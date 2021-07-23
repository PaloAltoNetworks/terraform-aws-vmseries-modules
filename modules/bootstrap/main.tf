resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}${random_id.bucket_id.hex}"
  acl    = "private"
  tags   = var.global_tags
}

resource "aws_s3_bucket_object" "bootstrap_dirs" {
  for_each = toset(var.bootstrap_directories)

  bucket  = aws_s3_bucket.this.id
  key     = each.value
  content = "/dev/null"
}

resource "aws_s3_bucket_object" "bootstrap_files" {
  for_each = fileset("${path.root}/files", "**")

  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${path.root}/files/${each.value}"
}

resource "aws_iam_role" "this" {
  name = "${var.prefix}${random_id.bucket_id.hex}"

  tags               = var.global_tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "bootstrap" {
  name   = "${var.prefix}${random_id.bucket_id.hex}"
  role   = aws_iam_role.this.id
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.bucket}"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${aws_s3_bucket.this.bucket}/*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.iam_instance_profile_name, "${var.prefix}${random_id.bucket_id.hex}")
  role = aws_iam_role.this.name
  path = "/"
}
