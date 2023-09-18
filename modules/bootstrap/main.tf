resource "random_id" "sufix" {
  byte_length = 8
}

locals {
  random_name   = "${var.prefix}${random_id.sufix.hex}"
  bucket_name   = coalesce(var.bucket_name, local.random_name)
  aws_s3_bucket = var.create_bucket ? aws_s3_bucket.this[0] : data.aws_s3_bucket.this[0]
  iam_role_name = coalesce(var.iam_role_name, local.random_name)
  aws_iam_role  = var.create_iam_role_policy ? aws_iam_role.this[0] : data.aws_iam_role.this[0]
}

data "aws_s3_bucket" "this" {
  count = var.create_bucket == false ? 1 : 0

  bucket = local.bucket_name
}

resource "aws_s3_bucket" "this" {
  count = var.create_bucket == true ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = var.global_tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "this" {
  count = var.create_bucket == true ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.this[0]]
}

resource "aws_s3_object" "bootstrap_dirs" {
  for_each = toset(var.bootstrap_directories)

  bucket  = local.aws_s3_bucket.id
  key     = each.value
  content = "/dev/null"
}

resource "aws_s3_object" "init_cfg" {
  count = contains(fileset(local.source_root_directory, "**"), "config/init-cfg.txt") ? 0 : 1

  bucket = local.aws_s3_bucket.id
  key    = "config/init-cfg.txt"
  content = templatefile("${path.module}/init-cfg.txt.tmpl",
    {
      "hostname"                    = var.hostname,
      "panorama-server"             = var.panorama-server,
      "panorama-server2"            = var.panorama-server2,
      "tplname"                     = var.tplname,
      "dgname"                      = var.dgname,
      "dns-primary"                 = var.dns-primary,
      "dns-secondary"               = var.dns-secondary,
      "vm-auth-key"                 = var.vm-auth-key,
      "op-command-modes"            = var.op-command-modes,
      "plugin-op-commands"          = var.plugin-op-commands,
      "dhcp-send-hostname"          = var.dhcp_send_hostname,
      "dhcp-send-client-id"         = var.dhcp_send_client_id,
      "dhcp-accept-server-hostname" = var.dhcp_accept_server_hostname,
      "dhcp-accept-server-domain"   = var.dhcp_accept_server_domain
    }
  )
}

locals {
  source_root_directory = coalesce(var.source_root_directory, "${path.root}/files")
}

resource "aws_s3_object" "bootstrap_files" {
  for_each = fileset(local.source_root_directory, "**")

  bucket = local.aws_s3_bucket.id
  key    = each.value
  source = "${local.source_root_directory}/${each.value}"
}

data "aws_iam_role" "this" {
  count = var.create_iam_role_policy == false && var.iam_role_name != null ? 1 : 0

  name = var.iam_role_name
}

# Lookup information about the current AWS partition in which Terraform is working (e.g. `aws`, `aws-us-gov`, `aws-cn`)
data "aws_partition" "this" {}

resource "aws_iam_role" "this" {
  count = var.create_iam_role_policy ? 1 : 0

  name = local.iam_role_name

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
  count = var.create_iam_role_policy ? 1 : 0

  name   = local.iam_role_name
  role   = local.aws_iam_role.id
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:${data.aws_partition.this.partition}:s3:::${local.aws_s3_bucket.bucket}"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:${data.aws_partition.this.partition}:s3:::${local.aws_s3_bucket.bucket}/*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.iam_instance_profile_name, local.random_name)
  role = local.aws_iam_role.name
  path = "/"
}
