output "name_template" {
  value = local.name_template
}

output "vpc_name" {
  value = {
    for k, v in var.names.vpc.values : k => replace(
      format(local.name_template[var.names.vpc.template], v),
      "__default__",
      "vpc"
    )
  }
}

output "subnet_name" {
  value = {
    for k, v in var.names.subnet.values : k => replace(
      format(local.name_template[var.names.subnet.template], v),
      "__default__",
      "snet"
    )
  }
}

output "route_table_name" {
  value = {
    for k, v in var.names.subnet.values : k => replace(
      format(local.name_template[var.names.subnet.template], v),
      "__default__",
      "rt"
    )
  }
}

output "nat_gateway_name" {
  value = {
    for k, v in var.names.nat_gateway.values : k => replace(
      format(local.name_template[var.names.nat_gateway.template], v),
      "__default__",
      "ngw"
    )
  }
}
