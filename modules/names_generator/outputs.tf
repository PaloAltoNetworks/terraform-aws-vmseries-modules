output "generated" {
  description = <<-EOF
  Map of generated names for each kind of resources.

  Example:

  generated = {
      application_loadbalancer              = {
          app1 = "example-alb-app1-cloud-tst-ec1"
          app2 = "example-alb-app2-cloud-tst-ec1"
      }
      application_loadbalancer_target_group = {
          app1-http = "example-atg-app1-80-cloud-tst"
          app2-http = "example-atg-app2-80-cloud-tst"
      }
      gateway_loadbalancer                  = {
          security_gwlb = "scz-gwlb-security-cloud-tst"
      }
      gateway_loadbalancer_endpoint         = {
          app1_inbound           = "example-gwep-app1-cloud-tst-ec1"
          app2_inbound           = "example-gwep-app2-cloud-tst-ec1"
          security_gwlb_eastwest = "example-gwep-eastwest-cloud-tst-ec1"
          security_gwlb_outbound = "example-gwep-outbound-cloud-tst-ec1"
      }
  }

  EOF
  value = {
    # for every kind of resource
    for m, n in var.names : m => {
      # for every resource of the same type
      for k, v in n : k => trim(
        replace(
          replace(
            replace(
              # at first check if template contains %s - if yes, the use format function
              length(regexall("%s", local.name_templates[try(var.template_assignments[m], try(var.template_assignments["default"], "default"))])) > 0 ? format(
                local.name_templates[try(var.template_assignments[m], try(var.template_assignments["default"], "default"))], split(var.region, v)[0]
                # if no, the just use template without format
              ) : local.name_templates[try(var.template_assignments[m], try(var.template_assignments["default"], "default"))],
              # replace __default__ by abbreviations specific for resource
              "__default__",
              var.abbreviations[m]
            ),
            # replace __az_numeric__ with number for availability zone
            "__az_numeric__",
            try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
          ),
          # replace __az_literal__ by letter for availability zone
          "__az_literal__",
          try(split(var.region, v)[1], "")
        ),
        # remove delimiter from the beginning and end of string (if required in some cases)
      var.name_templates[try(var.template_assignments[m], try(var.template_assignments["default"], "default"))].delimiter)
    }
  }
}

output "template" {
  description = <<-EOF
  Single template ready to be used with format function

  Example:

  EOF
  value = try(
    replace(
      local.name_template,
      # replace __default__ by abbreviations specific for resource
      "__default__",
      var.abbreviations[var.resource_type]
    ),
  null)
}

output "az_map_literal_to_numeric" {
  description = <<-EOF
  Map of number used instead of letters for AZs (placed in place of "__az_numeric__").
  EOF
  value       = var.az_map_literal_to_numeric
}