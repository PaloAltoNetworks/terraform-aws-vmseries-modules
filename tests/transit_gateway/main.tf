# Random ID used in names of the resoruces created for tests
resource "random_string" "random_sufix" {
  length  = 16
  special = false
}

# Transit gateway (without attachments)
module "transit_gateway" {
  source = "../../modules/transit_gateway"

  name         = var.transit_gateway_name != null ? "${var.name_prefix}${random_string.random_sufix.id}_${var.transit_gateway_name}" : null
  asn          = var.transit_gateway_asn
  route_tables = var.transit_gateway_route_tables
}

