variable "name_prefix" {
  description = "A prefix added to all resource names created by this module"
  default     = ""
  type        = string
}

variable "name_suffix" {
  description = "A sufix added to all resource names created by this module"
  default     = ""
  type        = string
}

variable "tags" {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}

variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}

variable "customer_gateway" {
  description = <<-EOF
  Customer gateway defined by attributes:
  - bgp_asn - (Required) The gateway's Border Gateway Protocol (BGP) Autonomous System Number (ASN).
  - certificate_arn - (Optional) The Amazon Resource Name (ARN) for the customer gateway certificate.
  - device_name - (Optional) A name for the customer gateway device.
  - ip_address - (Optional) The IPv4 address for the customer gateway device's outside interface.
  - type - (Required) The type of customer gateway. The only type AWS supports at this time is "ipsec.1".
  - tags - (Optional) Tags to apply to the gateway. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  type        = any
}
variable "vpn_connection" {
  description = <<-EOF
  VPN connection defined by attributes:
  - customer_gateway_id - (Required) The ID of the customer gateway.
  - type - (Required) The type of VPN connection. The only type AWS supports at this time is "ipsec.1".
  - transit_gateway_id - (Optional) The ID of the EC2 Transit Gateway.
  - static_routes_only - (Optional, Default false) Whether the VPN connection uses static routes exclusively. Static routes must be used for devices that don't support BGP.
  - enable_acceleration - (Optional, Default false) Indicate whether to enable acceleration for the VPN connection. Supports only EC2 Transit Gateway.
  - tags - (Optional) Tags to apply to the connection. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  - local_ipv4_network_cidr - (Optional, Default 0.0.0.0/0) The IPv4 CIDR on the customer gateway (on-premises) side of the VPN connection.
  - local_ipv6_network_cidr - (Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection.
  - outside_ip_address_type - (Optional, Default PublicIpv4) Indicates if a Public S2S VPN or Private S2S VPN over AWS Direct Connect. Valid values are PublicIpv4 | PrivateIpv4
  - remote_ipv4_network_cidr - (Optional, Default 0.0.0.0/0) The IPv4 CIDR on the AWS side of the VPN connection.
  - remote_ipv6_network_cidr - (Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection.
  - transport_transit_gateway_attachment_id - (Required when outside_ip_address_type is set to PrivateIpv4). The attachment ID of the Transit Gateway attachment to Direct Connect Gateway. The ID is obtained through a data source only.
  - tunnel_inside_ip_version - (Optional, Default ipv4) Indicate whether the VPN tunnels process IPv4 or IPv6 traffic. Valid values are ipv4 | ipv6. ipv6 Supports only EC2 Transit Gateway.
  - tunnel1_inside_cidr - (Optional) The CIDR block of the inside IP addresses for the first VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range.
  - tunnel2_inside_cidr - (Optional) The CIDR block of the inside IP addresses for the second VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range.
  - tunnel1_inside_ipv6_cidr - (Optional) The range of inside IPv6 addresses for the first VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range.
  - tunnel2_inside_ipv6_cidr - (Optional) The range of inside IPv6 addresses for the second VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range.
  - tunnel1_preshared_key - (Optional) The preshared key of the first VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(_).
  - tunnel2_preshared_key - (Optional) The preshared key of the second VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(_).
  - tunnel1_dpd_timeout_action - (Optional, Default clear) The action to take after DPD timeout occurs for the first VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear | none | restart.
  - tunnel2_dpd_timeout_action - (Optional, Default clear) The action to take after DPD timeout occurs for the second VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear | none | restart.
  - tunnel1_dpd_timeout_seconds - (Optional, Default 30) The number of seconds after which a DPD timeout occurs for the first VPN tunnel. Valid value is equal or higher than 30.
  - tunnel2_dpd_timeout_seconds - (Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30.
  - tunnel1_enable_tunnel_lifecycle_control - (Optional, Default false) Turn on or off tunnel endpoint lifecycle control feature for the first VPN tunnel. Valid values are true | false.
  - tunnel2_enable_tunnel_lifecycle_control - (Optional, Default false) Turn on or off tunnel endpoint lifecycle control feature for the second VPN tunnel. Valid values are true | false.
  - tunnel1_ike_versions - (Optional) The IKE versions that are permitted for the first VPN tunnel. Valid values are ikev1 | ikev2.
  - tunnel2_ike_versions - (Optional) The IKE versions that are permitted for the second VPN tunnel. Valid values are ikev1 | ikev2.
  - tunnel1_log_options - (Required) Options for logging VPN tunnel activity:
    - enabled - (Required) true if logs need to stored in CloudWatch logs
    - log_group - (Required) The name of the log group.
    - retention_in_days - (Required) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.
    - encrypted - (Required) true if logs need to be encrypted
  - tunnel2_log_options - (Required) Options for logging VPN tunnel activity:
    - enabled - (Required) Required if logs need to stored in CloudWatch logs
    - log_group - (Required) The name of the log group.
    - retention_in_days - (Required) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.
    - encrypted - (Required) true if logs need to be encrypted
  - tunnel1_phase1_dh_group_numbers - (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24.
  - tunnel2_phase1_dh_group_numbers - (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24.
  - tunnel1_phase1_encryption_algorithms - (Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16.
  - tunnel2_phase1_encryption_algorithms - (Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16.
  - tunnel1_phase1_integrity_algorithms - (Optional) One or more integrity algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512.
  - tunnel2_phase1_integrity_algorithms - (Optional) One or more integrity algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512.
  - tunnel1_phase1_lifetime_seconds - (Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 28800.
  - tunnel2_phase1_lifetime_seconds - (Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 28800.
  - tunnel1_phase2_dh_group_numbers - (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24.
  - tunnel2_phase2_dh_group_numbers - (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24.
  - tunnel1_phase2_encryption_algorithms - (Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16.
  - tunnel2_phase2_encryption_algorithms - (Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16.
  - tunnel1_phase2_integrity_algorithms - (Optional) List of one or more integrity algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512.
  - tunnel2_phase2_integrity_algorithms - (Optional) List of one or more integrity algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512.
  - tunnel1_phase2_lifetime_seconds - (Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 3600.
  - tunnel2_phase2_lifetime_seconds - (Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 3600.
  - tunnel1_rekey_fuzz_percentage - (Optional, Default 100) The percentage of the rekey window for the first VPN tunnel (determined by tunnel1_rekey_margin_time_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100.
  - tunnel2_rekey_fuzz_percentage - (Optional, Default 100) The percentage of the rekey window for the second VPN tunnel (determined by tunnel2_rekey_margin_time_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100.
  - tunnel1_rekey_margin_time_seconds - (Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the first VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel1_rekey_fuzz_percentage. Valid value is between 60 and half of tunnel1_phase2_lifetime_seconds.
  - tunnel2_rekey_margin_time_seconds - (Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the second VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel2_rekey_fuzz_percentage. Valid value is between 60 and half of tunnel2_phase2_lifetime_seconds.
  - tunnel1_replay_window_size - (Optional, Default 1024) The number of packets in an IKE replay window for the first VPN tunnel. Valid value is between 64 and 2048.
  - tunnel2_replay_window_size - (Optional, Default 1024) The number of packets in an IKE replay window for the second VPN tunnel. Valid value is between 64 and 2048.
  - tunnel1_startup_action - (Optional, Default add) The action to take when the establishing the tunnel for the first VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add | start.
  - tunnel2_startup_action - (Optional, Default add) The action to take when the establishing the tunnel for the second VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add | start.
  EOF
  type        = any
}

variable "transit_gateway_id" {
  description = "TGW's ID used by VPN connection"
  type        = string
}
variable "transit_gateway_associate_route_table_id" {
  description = "TGW route table ID used to associate VPN attachments created by VPN connections"
  type        = string
}
variable "transit_gateway_propagate_route_table_id" {
  description = "TGW route table ID into which VPN attachment will propagate routes received by BGP"
  type        = string
}