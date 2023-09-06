output "customer_gateway" {
  description = "Object describing created customer gateway"
  value       = aws_customer_gateway.this
}

output "vpn_connection" {
  description = "Object describing created Site-to-Site VPN connection"
  value       = aws_vpn_connection.this
}

output "tunnel1" {
  description = "Tunnel 1 details (public IP address, inside IP addresses, BGP ASN)"
  value = {
    outside_ip_address : aws_vpn_connection.this.tunnel1_address
    inside_ip_address_aws : aws_vpn_connection.this.tunnel1_vgw_inside_address
    inside_ip_address_cgw : aws_vpn_connection.this.tunnel1_cgw_inside_address
    bgp_asn : aws_vpn_connection.this.tunnel1_bgp_asn
    ipsec_policy : {
      phase1_dh_group_numbers : one(aws_vpn_connection.this.tunnel1_phase1_dh_group_numbers)
      phase1_encryption_algorithms : one(aws_vpn_connection.this.tunnel1_phase1_encryption_algorithms)
      phase1_integrity_algorithms : one(aws_vpn_connection.this.tunnel1_phase1_integrity_algorithms)
      phase2_dh_group_numbers : one(aws_vpn_connection.this.tunnel1_phase2_dh_group_numbers)
      phase2_encryption_algorithms : one(aws_vpn_connection.this.tunnel1_phase2_encryption_algorithms)
      phase2_integrity_algorithms : one(aws_vpn_connection.this.tunnel1_phase2_integrity_algorithms)
    }
  }
}

output "tunnel2" {
  description = "Tunnel 2 details (public IP address, inside IP addresses, BGP ASN)"
  value = {
    outside_ip_address : aws_vpn_connection.this.tunnel2_address
    inside_ip_address_aws : aws_vpn_connection.this.tunnel2_vgw_inside_address
    inside_ip_address_cgw : aws_vpn_connection.this.tunnel2_cgw_inside_address
    bgp_asn : aws_vpn_connection.this.tunnel2_bgp_asn
    ipsec_policy : {
      phase1_dh_group_numbers : one(aws_vpn_connection.this.tunnel2_phase1_dh_group_numbers)
      phase1_encryption_algorithms : one(aws_vpn_connection.this.tunnel2_phase1_encryption_algorithms)
      phase1_integrity_algorithms : one(aws_vpn_connection.this.tunnel2_phase1_integrity_algorithms)
      phase2_dh_group_numbers : one(aws_vpn_connection.this.tunnel2_phase2_dh_group_numbers)
      phase2_encryption_algorithms : one(aws_vpn_connection.this.tunnel2_phase2_encryption_algorithms)
      phase2_integrity_algorithms : one(aws_vpn_connection.this.tunnel2_phase2_integrity_algorithms)
    }
  }
}