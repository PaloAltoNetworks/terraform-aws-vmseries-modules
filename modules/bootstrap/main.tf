resource "random_id" "bucket_id" {
  byte_length = 8
}

locals {
  bucket_name   = coalesce(var.bucket_name, "${var.prefix}${random_id.bucket_id.hex}")
  aws_s3_bucket = var.create_bucket ? aws_s3_bucket.this[0] : data.aws_s3_bucket.this[0]
}

# Either use a pre-existing resource or create a new one. So, is it a pre-existing VPC then?
data "aws_s3_bucket" "this" {
  count = var.create_bucket == false ? 1 : 0

  bucket = local.bucket_name
}

resource "aws_s3_bucket" "this" {
  count = var.create_bucket ? 1 : 0

  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = var.force_destroy
  tags          = var.global_tags
}

resource "aws_s3_bucket_object" "bootstrap_dirs" {
  for_each = toset(var.bootstrap_directories)

  bucket  = local.aws_s3_bucket.id
  key     = each.value
  content = "/dev/null"
}

resource "aws_s3_bucket_object" "init_cfg" {
  count = contains(fileset(local.source_root_directory, "**"), "config/init-cfg.txt") ? 0 : 1

  bucket = local.aws_s3_bucket.id
  key    = "config/init-cfg.txt"
  content = templatefile("${path.module}/init-cfg.txt.tmpl",
    {
      "hostname"           = var.hostname,
      "panorama-server"    = var.panorama-server,
      "panorama-server2"   = var.panorama-server2,
      "tplname"            = var.tplname,
      "dgname"             = var.dgname,
      "dns-primary"        = var.dns-primary,
      "dns-secondary"      = var.dns-secondary,
      "vm-auth-key"        = var.vm-auth-key,
      "op-command-modes"   = var.op-command-modes,
      "plugin-op-commands" = var.plugin-op-commands
    }
  )
}

locals {
  source_root_directory = coalesce(var.source_root_directory, "${path.root}/files")
}

resource "aws_s3_bucket_object" "bootstrap_files" {
  for_each = fileset(local.source_root_directory, "**")

  bucket = local.aws_s3_bucket.id
  key    = each.value
  source = "${local.source_root_directory}/${each.value}"
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
      "Resource": "arn:aws:s3:::${local.aws_s3_bucket.bucket}"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${local.aws_s3_bucket.bucket}/*"
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
