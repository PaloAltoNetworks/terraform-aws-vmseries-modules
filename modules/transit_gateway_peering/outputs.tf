output "peering_attachment" {
  description = "The TGW Peering Attachment object, created under the provider `aws`."
  value       = aws_ec2_transit_gateway_peering_attachment.this
}

output "peering_attachment_accepter" {
  description = "The Accepter object, created under the provider `aws.remote`."
  value       = aws_ec2_transit_gateway_peering_attachment_accepter.remote
}

output "local_route_table" {
  description = "The route table associated to the TGW Peering Attachment, owned by the provider `aws`."
  value       = var.local_tgw_route_table
}

output "remote_route_table" {
  description = "The route table associated to the TGW Peering Attachment, owned by the provider `aws.remote`."
  value       = var.remote_tgw_route_table
}
