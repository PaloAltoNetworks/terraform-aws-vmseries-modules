variable "local_tgw_route_table" {
  description = <<-EOF
  Local TGW's pre-existing route table which should handle the traffic coming from the peered TGW (also called a route table association). An object with two attributes, the `id` of the local route table and the `transit_gateway_id` of the local TGW:
  ```
  transit_gateway_route_table = {
    id                 = "tgw-rtb-1234"
    transit_gateway_id = "tgw-1234"
  }
  ```
  EOF
  type = object({
    id                 = string
    transit_gateway_id = string
  })
}

variable "peer_tgw_route_table" {
  description = <<-EOF
  Analog to the `local_tgw_route_table` but on the remote end of the peering.
  EOF
  type = object({
    id                 = string
    transit_gateway_id = string
  })
}

variable "local_attachment_tags" {
  description = "AWS tags to assign to the Attachment object. The tags are only visible in the UI when logged on the local account, but not on the remote peer account. Example: `{ Name = \"my-name\" }`"
  default     = {}
  type        = map(string)
}

variable "tags" {
  description = "AWS tags to assign to all the created objects. Example: `{ Team = \"my-team\" }`"
  default     = {}
  type        = map(string)
}
