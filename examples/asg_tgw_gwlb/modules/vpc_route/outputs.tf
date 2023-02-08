output "route_details" {
  value = [for k, v in aws_route.this : {
    cidr = v.destination_cidr_block
    mpl  = v.destination_prefix_list_id
    rtb  = v.route_table_id
    }
  ]
}