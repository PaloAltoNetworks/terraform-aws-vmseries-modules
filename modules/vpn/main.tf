# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway
resource "aws_customer_gateway" "this" {
  bgp_asn    = var.customer_gateway.bgp_asn
  ip_address = var.customer_gateway.ip_address
  type       = try(var.customer_gateway.type, "ipsec.1")

  tags = merge(var.tags, { Name = "${var.name_prefix}${var.customer_gateway.name}${var.name_suffix}" })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection
resource "aws_vpn_connection" "this" {
  customer_gateway_id                     = aws_customer_gateway.this.id
  type                                    = aws_customer_gateway.this.type
  vpn_gateway_id                          = try(var.vpn_gateway_id, null)
  transit_gateway_id                      = try(var.transit_gateway_id, null)
  static_routes_only                      = try(var.vpn_connection.static_routes_only, false)
  enable_acceleration                     = try(var.vpn_connection.enable_acceleration, false)
  local_ipv4_network_cidr                 = try(var.vpn_connection.local_ipv4_network_cidr, "0.0.0.0/0")
  outside_ip_address_type                 = try(var.vpn_connection.outside_ip_address_type, "PublicIpv4")
  remote_ipv4_network_cidr                = try(var.vpn_connection.remote_ipv4_network_cidr, "0.0.0.0/0")
  tunnel_inside_ip_version                = try(var.vpn_connection.tunnel_inside_ip_version, "ipv4")
  tunnel1_inside_cidr                     = try(var.vpn_connection.tunnel1_inside_cidr, null)
  tunnel2_inside_cidr                     = try(var.vpn_connection.tunnel2_inside_cidr, null)
  tunnel1_preshared_key                   = try(var.vpn_connection.tunnel1_preshared_key, null)
  tunnel2_preshared_key                   = try(var.vpn_connection.tunnel2_preshared_key, null)
  tunnel1_dpd_timeout_action              = try(var.vpn_connection.tunnel1_dpd_timeout_action, null)
  tunnel2_dpd_timeout_action              = try(var.vpn_connection.tunnel2_dpd_timeout_action, null)
  tunnel1_dpd_timeout_seconds             = try(var.vpn_connection.tunnel1_dpd_timeout_seconds, null)
  tunnel2_dpd_timeout_seconds             = try(var.vpn_connection.tunnel2_dpd_timeout_seconds, null)
  tunnel1_enable_tunnel_lifecycle_control = try(var.vpn_connection.tunnel1_enable_tunnel_lifecycle_control, null)
  tunnel2_enable_tunnel_lifecycle_control = try(var.vpn_connection.tunnel2_enable_tunnel_lifecycle_control, null)
  tunnel1_ike_versions                    = try(var.vpn_connection.tunnel1_ike_versions, null)
  tunnel2_ike_versions                    = try(var.vpn_connection.tunnel2_ike_versions, null)
  tunnel1_phase1_dh_group_numbers         = try(var.vpn_connection.tunnel1_phase1_dh_group_numbers, null)
  tunnel2_phase1_dh_group_numbers         = try(var.vpn_connection.tunnel2_phase1_dh_group_numbers, null)
  tunnel1_phase1_encryption_algorithms    = try(var.vpn_connection.tunnel1_phase1_encryption_algorithms, null)
  tunnel2_phase1_encryption_algorithms    = try(var.vpn_connection.tunnel2_phase1_encryption_algorithms, null)
  tunnel1_phase1_integrity_algorithms     = try(var.vpn_connection.tunnel1_phase1_integrity_algorithms, null)
  tunnel2_phase1_integrity_algorithms     = try(var.vpn_connection.tunnel2_phase1_integrity_algorithms, null)
  tunnel1_phase1_lifetime_seconds         = try(var.vpn_connection.tunnel1_phase1_lifetime_seconds, 28800)
  tunnel2_phase1_lifetime_seconds         = try(var.vpn_connection.tunnel2_phase1_lifetime_seconds, 28800)
  tunnel1_phase2_dh_group_numbers         = try(var.vpn_connection.tunnel1_phase2_dh_group_numbers, null)
  tunnel2_phase2_dh_group_numbers         = try(var.vpn_connection.tunnel2_phase2_dh_group_numbers, null)
  tunnel1_phase2_encryption_algorithms    = try(var.vpn_connection.tunnel1_phase2_encryption_algorithms, null)
  tunnel2_phase2_encryption_algorithms    = try(var.vpn_connection.tunnel2_phase2_encryption_algorithms, null)
  tunnel1_phase2_integrity_algorithms     = try(var.vpn_connection.tunnel1_phase2_integrity_algorithms, null)
  tunnel2_phase2_integrity_algorithms     = try(var.vpn_connection.tunnel2_phase2_integrity_algorithms, null)
  tunnel1_phase2_lifetime_seconds         = try(var.vpn_connection.tunnel1_phase2_lifetime_seconds, 3600)
  tunnel2_phase2_lifetime_seconds         = try(var.vpn_connection.tunnel2_phase2_lifetime_seconds, 3600)
  tunnel1_rekey_fuzz_percentage           = try(var.vpn_connection.tunnel1_rekey_fuzz_percentage, 100)
  tunnel2_rekey_fuzz_percentage           = try(var.vpn_connection.tunnel2_rekey_fuzz_percentage, 100)
  tunnel1_rekey_margin_time_seconds       = try(var.vpn_connection.tunnel1_rekey_margin_time_seconds, null)
  tunnel2_rekey_margin_time_seconds       = try(var.vpn_connection.tunnel2_rekey_margin_time_seconds, null)
  tunnel1_replay_window_size              = try(var.vpn_connection.tunnel1_replay_window_size, null)
  tunnel2_replay_window_size              = try(var.vpn_connection.tunnel2_replay_window_size, null)
  tunnel1_startup_action                  = try(var.vpn_connection.tunnel1_startup_action, null)
  tunnel2_startup_action                  = try(var.vpn_connection.tunnel2_startup_action, null)

  dynamic "tunnel1_log_options" {
    for_each = try(var.vpn_connection.tunnel1_log_options.enabled, false) ? { log_options = var.vpn_connection.tunnel1_log_options } : {}
    content {
      cloudwatch_log_options {
        log_enabled       = try(var.vpn_connection.tunnel1_log_options.enabled, false)
        log_group_arn     = try(aws_cloudwatch_log_group.tunnel1_log[0].arn, null)
        log_output_format = try(var.vpn_connection.tunnel1_log_options.output_format, "json")
      }
    }
  }
  dynamic "tunnel2_log_options" {
    for_each = try(var.vpn_connection.tunnel2_log_options.enabled, false) ? { log_options = var.vpn_connection.tunnel2_log_options } : {}
    content {
      cloudwatch_log_options {
        log_enabled       = try(var.vpn_connection.tunnel2_log_options.enabled, false)
        log_group_arn     = try(aws_cloudwatch_log_group.tunnel2_log[0].arn, null)
        log_output_format = try(var.vpn_connection.tunnel2_log_options.output_format, "json")
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}${var.vpn_connection.name}${var.name_suffix}" })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association.html
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_associate_route_table_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_propagate_route_table_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "tunnel1_log" {
  count             = var.vpn_connection.tunnel1_log_options.enabled ? 1 : 0
  name              = "${var.name_prefix}log-${var.vpn_connection.tunnel1_log_options.log_group}${var.name_suffix}"
  retention_in_days = var.vpn_connection.tunnel1_log_options.retention_in_days
  kms_key_id        = var.vpn_connection.tunnel1_log_options.encrypted ? aws_kms_key.tunnel1_kms_key[0].arn : null

  tags = merge(var.tags)
}

resource "aws_cloudwatch_log_group" "tunnel2_log" {
  count             = var.vpn_connection.tunnel2_log_options.enabled ? 1 : 0
  name              = "${var.name_prefix}log-${var.vpn_connection.tunnel2_log_options.log_group}${var.name_suffix}"
  retention_in_days = var.vpn_connection.tunnel2_log_options.retention_in_days
  kms_key_id        = var.vpn_connection.tunnel2_log_options.encrypted ? aws_kms_key.tunnel2_kms_key[0].arn : null

  tags = var.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
resource "aws_kms_key" "tunnel1_kms_key" {
  count                   = var.vpn_connection.tunnel1_log_options.enabled && var.vpn_connection.tunnel1_log_options.encrypted ? 1 : 0
  description             = "KMS key for encrypting CloudWatch logs for VPN connections"
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.this.json

  tags = var.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias
resource "aws_kms_alias" "tunnel1_kms_alias" {
  count         = var.vpn_connection.tunnel1_log_options.enabled && var.vpn_connection.tunnel1_log_options.encrypted ? 1 : 0
  name          = "alias/${var.name_prefix}kms-${var.vpn_connection.tunnel1_log_options.log_group}${var.name_suffix}"
  target_key_id = aws_kms_key.tunnel1_kms_key[0].key_id
}

resource "aws_kms_key" "tunnel2_kms_key" {
  count                   = var.vpn_connection.tunnel2_log_options.enabled && var.vpn_connection.tunnel2_log_options.encrypted ? 1 : 0
  description             = "KMS key for encrypting CloudWatch logs for VPN connections"
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.this.json

  tags = var.tags
}

resource "aws_kms_alias" "tunnel2_kms_alias" {
  count         = var.vpn_connection.tunnel2_log_options.enabled && var.vpn_connection.tunnel2_log_options.encrypted ? 1 : 0
  name          = "alias/${var.name_prefix}kms-${var.vpn_connection.tunnel2_log_options.log_group}${var.name_suffix}"
  target_key_id = aws_kms_key.tunnel2_kms_key[0].key_id
}

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

# actions, resources, and condition keys for AWS Key Management Service: https://docs.aws.amazon.com/service-authorization/latest/reference/list_awskeymanagementservice.html
data "aws_iam_policy_document" "this" {
  policy_id = "key-policy-cloudwatch"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.this.partition,
          data.aws_caller_identity.this.account_id
        )
      ]
    }
    resources = [
      format(
        "arn:%s:kms:%s:%s:key/*",
        data.aws_partition.this.partition,
        var.region,
        data.aws_caller_identity.this.account_id
      )
    ]
  }
  statement {
    sid = "Allow use of the key by CloudWatch logs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        format(
          "logs.%s.amazonaws.com",
          var.region
        )
      ]
    }
    resources = [
      format(
        "arn:%s:kms:%s:%s:key/*",
        data.aws_partition.this.partition,
        var.region,
        data.aws_caller_identity.this.account_id
      )
    ]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.this.partition}:logs:${var.region}:${data.aws_caller_identity.this.account_id}:*"]
    }
  }
}