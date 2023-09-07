output "name_template" {
  value = local.name_template
}

output "vpc_name" {
  value = {
    for k, v in var.names.vpc.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.vpc.template], "%s") ? format(
              local.name_template[var.names.vpc.template], split(var.region, v)[0]
            ) : local.name_template[var.names.vpc.template],
            "__default__",
            var.abbreviations.vpc
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "internet_gateway_name" {
  value = {
    for k, v in var.names.internet_gateway.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.internet_gateway.template], "%s") ? format(
              local.name_template[var.names.internet_gateway.template], split(var.region, v)[0]
            ) : local.name_template[var.names.internet_gateway.template],
            "__default__",
            var.abbreviations.igw
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "vpn_gateway_name" {
  value = {
    for k, v in var.names.vpn_gateway.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.vpn_gateway.template], "%s") ? format(
              local.name_template[var.names.vpn_gateway.template], split(var.region, v)[0]
            ) : local.name_template[var.names.vpn_gateway.template],
            "__default__",
            var.abbreviations.vgw
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "subnet_name" {
  value = {
    for k, v in var.names.subnet.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.subnet.template], "%s") ? format(
              local.name_template[var.names.subnet.template], split(var.region, v)[0]
            ) : local.name_template[var.names.subnet.template],
            "__default__",
            var.abbreviations.snet
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "route_table_name" {
  value = {
    for k, v in var.names.route_table.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.route_table.template], "%s") ? format(
              local.name_template[var.names.route_table.template], split(var.region, v)[0]
            ) : local.name_template[var.names.route_table.template],
            "__default__",
            var.abbreviations.rt
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "nat_gateway_name" {
  value = {
    for k, v in var.names.nat_gateway.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.nat_gateway.template], "%s") ? format(
              local.name_template[var.names.nat_gateway.template], split(var.region, v)[0]
            ) : local.name_template[var.names.nat_gateway.template],
            "__default__",
            var.abbreviations.ngw
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "transit_gateway_name" {
  value = {
    for k, v in var.names.transit_gateway.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.transit_gateway.template], "%s") ? format(
              local.name_template[var.names.transit_gateway.template], split(var.region, v)[0]
            ) : local.name_template[var.names.transit_gateway.template],
            "__default__",
            var.abbreviations.tgw
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "transit_gateway_attachment_name" {
  value = {
    for k, v in var.names.transit_gateway_attachment.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.transit_gateway_attachment.template], "%s") ? format(
              local.name_template[var.names.transit_gateway_attachment.template], split(var.region, v)[0]
            ) : local.name_template[var.names.transit_gateway_attachment.template],
            "__default__",
            var.abbreviations.tgw_att
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "gateway_loadbalancer_name" {
  value = {
    for k, v in var.names.gateway_loadbalancer.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.gateway_loadbalancer.template], "%s") ? format(
              local.name_template[var.names.gateway_loadbalancer.template], split(var.region, v)[0]
            ) : local.name_template[var.names.gateway_loadbalancer.template],
            "__default__",
            var.abbreviations.gwlb
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "gateway_loadbalancer_target_group_name" {
  value = {
    for k, v in var.names.gateway_loadbalancer_target_group.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.gateway_loadbalancer_target_group.template], "%s") ? format(
              local.name_template[var.names.gateway_loadbalancer_target_group.template], split(var.region, v)[0]
            ) : local.name_template[var.names.gateway_loadbalancer_target_group.template],
            "__default__",
            var.abbreviations.gwlb_tg
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "gateway_loadbalancer_endpoint_name" {
  value = {
    for k, v in var.names.gateway_loadbalancer_endpoint.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.gateway_loadbalancer_endpoint.template], "%s") ? format(
              local.name_template[var.names.gateway_loadbalancer_endpoint.template], split(var.region, v)[0]
            ) : local.name_template[var.names.gateway_loadbalancer_endpoint.template],
            "__default__",
            var.abbreviations.gwlb_ep
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "vm_name" {
  value = {
    for k, v in var.names.vm.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.vm.template], "%s") ? format(
              local.name_template[var.names.vm.template], split(var.region, v)[0]
            ) : local.name_template[var.names.vm.template],
            "__default__",
            var.abbreviations.vm
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "vmseries_name" {
  value = {
    for k, v in var.names.vmseries.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.vmseries.template], "%s") ? format(
              local.name_template[var.names.vmseries.template], split(var.region, v)[0]
            ) : local.name_template[var.names.vmseries.template],
            "__default__",
            var.abbreviations.vm
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "application_loadbalancer_name" {
  value = {
    for k, v in var.names.application_loadbalancer.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.application_loadbalancer.template], "%s") ? format(
              local.name_template[var.names.application_loadbalancer.template], split(var.region, v)[0]
            ) : local.name_template[var.names.application_loadbalancer.template],
            "__default__",
            var.abbreviations.alb
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "application_loadbalancer_target_group_name" {
  value = {
    for k, v in var.names.application_loadbalancer_target_group.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.application_loadbalancer_target_group.template], "%s") ? format(
              local.name_template[var.names.application_loadbalancer_target_group.template], split(var.region, v)[0]
            ) : local.name_template[var.names.application_loadbalancer_target_group.template],
            "__default__",
            var.abbreviations.alb_tg
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "network_loadbalancer_name" {
  value = {
    for k, v in var.names.network_loadbalancer.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.network_loadbalancer.template], "%s") ? format(
              local.name_template[var.names.network_loadbalancer.template], split(var.region, v)[0]
            ) : local.name_template[var.names.network_loadbalancer.template],
            "__default__",
            var.abbreviations.nlb
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "network_loadbalancer_target_group_name" {
  value = {
    for k, v in var.names.network_loadbalancer_target_group.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.network_loadbalancer_target_group.template], "%s") ? format(
              local.name_template[var.names.network_loadbalancer_target_group.template], split(var.region, v)[0]
            ) : local.name_template[var.names.network_loadbalancer_target_group.template],
            "__default__",
            var.abbreviations.nlb_tg
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "iam_role_name" {
  value = {
    for k, v in var.names.iam_role.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.iam_role.template], "%s") ? format(
              local.name_template[var.names.iam_role.template], split(var.region, v)[0]
            ) : local.name_template[var.names.iam_role.template],
            "__default__",
            var.abbreviations.role
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}

output "iam_instance_profile_name" {
  value = {
    for k, v in var.names.iam_instance_profile.values : k => trim(
      replace(
        replace(
          replace(
            strcontains(local.name_template[var.names.iam_instance_profile.template], "%s") ? format(
              local.name_template[var.names.iam_instance_profile.template], split(var.region, v)[0]
            ) : local.name_template[var.names.iam_instance_profile.template],
            "__default__",
            var.abbreviations.profile
          ),
          "__az_numeric__",
          try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
        ),
        "__az_literal__",
        try(split(var.region, v)[1], "")
      ),
    var.name_delimiter)
  }
}
