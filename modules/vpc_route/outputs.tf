output "destination_cidr_block" {
  value = { for k, v in aws_route.this : k => v.destination_cidr_block }
}

output "destination_managed_prefix_list_id" {
  value = { for k, v in aws_route.this : k => v.destination_prefix_list_id }
}

output "destination_managed_prefix_list_entries" {
  value = {
    for v in aws_ec2_managed_prefix_list.this : v.id => [
      for e in v.entry : e.cidr
    ]
  }
}