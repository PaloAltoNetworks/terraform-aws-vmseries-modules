output "peering_attachment" {
  description = "The TGW Peering Attachment object, created under the provider `aws`."
  value       = aws_ec2_transit_gateway_peering_attachment.this
}

output "peering_attachment_accepter" {
  description = "The Accepter object, created under the provider `aws.peer`."
  value       = aws_ec2_transit_gateway_peering_attachment_accepter.peer
}

output "local_route_table" {
  description = "The route table associated to the TGW Peering Attachment, owned by the provider `aws`."
  value       = var.local_tgw_route_table
}

output "peer_route_table" {
  description = "The route table associated to the TGW Peering Attachment, owned by the provider `aws.peer`."
  value       = var.peer_tgw_route_table
}
