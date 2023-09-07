output "name_template" {
  value = local.name_template
}

output "vpc_name" {
  value = {
    for k, v in var.names.vpc.values : k => replace(
      strcontains(local.name_template[var.names.vpc.template], "%s") ? format(local.name_template[var.names.vpc.template], v) : local.name_template[var.names.vpc.template],
      "__default__",
      var.abbreviations.vpc
    )
  }
}

output "subnet_name" {
  value = {
    for k, v in var.names.subnet.values : k => replace(
      strcontains(local.name_template[var.names.subnet.template], "%s") ? format(local.name_template[var.names.subnet.template], v) : local.name_template[var.names.subnet.template],
      "__default__",
      var.abbreviations.snet
    )
  }
}

output "route_table_name" {
  value = {
    for k, v in var.names.subnet.values : k => replace(
      strcontains(local.name_template[var.names.subnet.template], "%s") ? format(local.name_template[var.names.subnet.template], v) : local.name_template[var.names.subnet.template],
      "__default__",
      var.abbreviations.rt
    )
  }
}

output "nat_gateway_name" {
  value = {
    for k, v in var.names.nat_gateway.values : k => replace(
      strcontains(local.name_template[var.names.nat_gateway.template], "%s") ? format(local.name_template[var.names.nat_gateway.template], v) : local.name_template[var.names.nat_gateway.template],
      "__default__",
      var.abbreviations.ngw
    )
  }
}

output "transit_gateway_name" {
  value = {
    for k, v in var.names.transit_gateway.values : k => replace(
      strcontains(local.name_template[var.names.transit_gateway.template], "%s") ? format(local.name_template[var.names.transit_gateway.template], v) : local.name_template[var.names.transit_gateway.template],
      "__default__",
      var.abbreviations.tgw
    )
  }
}

output "transit_gateway_attachment_name" {
  value = {
    for k, v in var.names.transit_gateway_attachment.values : k => replace(
      strcontains(local.name_template[var.names.transit_gateway_attachment.template], "%s") ? format(local.name_template[var.names.transit_gateway_attachment.template], v) : local.name_template[var.names.transit_gateway_attachment.template],
      "__default__",
      var.abbreviations.tgw_att
    )
  }
}

output "gateway_loadbalancer_name" {
  value = {
    for k, v in var.names.gateway_loadbalancer.values : k => replace(
      strcontains(local.name_template[var.names.gateway_loadbalancer.template], "%s") ? format(local.name_template[var.names.gateway_loadbalancer.template], v) : local.name_template[var.names.gateway_loadbalancer.template],
      "__default__",
      var.abbreviations.gwlb
    )
  }
}

output "gateway_loadbalancer_endpoint_name" {
  value = {
    for k, v in var.names.gateway_loadbalancer_endpoint.values : k => replace(
      strcontains(local.name_template[var.names.gateway_loadbalancer_endpoint.template], "%s") ? format(local.name_template[var.names.gateway_loadbalancer_endpoint.template], v) : local.name_template[var.names.gateway_loadbalancer_endpoint.template],
      "__default__",
      var.abbreviations.gwlb_ep
    )
  }
}

output "vm_name" {
  value = {
    for k, v in var.names.vm.values : k => replace(
      strcontains(local.name_template[var.names.vm.template], "%s") ? format(local.name_template[var.names.vm.template], v) : local.name_template[var.names.vm.template],
      "__default__",
      var.abbreviations.vm
    )
  }
}

output "vmseries_name" {
  value = {
    for k, v in var.names.vmseries.values : k => replace(
      strcontains(local.name_template[var.names.vmseries.template], "%s") ? format(local.name_template[var.names.vmseries.template], v) : local.name_template[var.names.vmseries.template],
      "__default__",
      var.abbreviations.vm
    )
  }
}

output "application_loadbalancer_name" {
  value = {
    for k, v in var.names.application_loadbalancer.values : k => replace(
      strcontains(local.name_template[var.names.application_loadbalancer.template], "%s") ? format(local.name_template[var.names.application_loadbalancer.template], v) : local.name_template[var.names.application_loadbalancer.template],
      "__default__",
      var.abbreviations.alb
    )
  }
}

output "network_loadbalancer_name" {
  value = {
    for k, v in var.names.network_loadbalancer.values : k => replace(
      strcontains(local.name_template[var.names.network_loadbalancer.template], "%s") ? format(local.name_template[var.names.network_loadbalancer.template], v) : local.name_template[var.names.network_loadbalancer.template],
      "__default__",
      var.abbreviations.nlb
    )
  }
}

output "iam_role_name" {
  value = {
    for k, v in var.names.iam_role.values : k => replace(
      strcontains(local.name_template[var.names.iam_role.template], "%s") ? format(local.name_template[var.names.iam_role.template], v) : local.name_template[var.names.iam_role.template],
      "__default__",
      var.abbreviations.role
    )
  }
}

output "iam_instance_profile_name" {
  value = {
    for k, v in var.names.iam_instance_profile.values : k => replace(
      strcontains(local.name_template[var.names.iam_instance_profile.template], "%s") ? format(local.name_template[var.names.iam_instance_profile.template], v) : local.name_template[var.names.iam_instance_profile.template],
      "__default__",
      var.abbreviations.profile
    )
  }
}
