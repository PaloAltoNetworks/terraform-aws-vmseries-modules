output "template" {
  value = local.resource_name
}

# output "generated" {
#   description = <<-EOF
#   Map of generated names for each kind of resources.

#   Example:

#   generated = {
#       application_loadbalancer              = {
#           app1 = "example-alb-app1-cloud-tst-ec1"
#           app2 = "example-alb-app2-cloud-tst-ec1"
#       }
#       application_loadbalancer_target_group = {
#           app1-http = "example-atg-app1-80-cloud-tst"
#           app2-http = "example-atg-app2-80-cloud-tst"
#       }
#       gateway_loadbalancer                  = {
#           security_gwlb = "scz-gwlb-security-cloud-tst"
#       }
#       gateway_loadbalancer_endpoint         = {
#           app1_inbound           = "example-gwep-app1-cloud-tst-ec1"
#           app2_inbound           = "example-gwep-app2-cloud-tst-ec1"
#           security_gwlb_eastwest = "example-gwep-eastwest-cloud-tst-ec1"
#           security_gwlb_outbound = "example-gwep-outbound-cloud-tst-ec1"
#       }
#   }

#   EOF
#   value = {
#     # for every kind of resource
#     for m, n in var.names : m => {
#       # for every resource of the same type
#       for k, v in n : k => trim(
#         replace(
#           replace(
#             replace(
#               # at first check if template contains %s - if yes, the use format function
#               length(regexall("%s", local.name_template[try(var.assigned_template[m], try(var.assigned_template["default"], "default"))])) > 0 ? format(
#                 local.name_template[try(var.assigned_template[m], try(var.assigned_template["default"], "default"))], split(var.region, v)[0]
#                 # if no, the just use template without format
#               ) : local.name_template[try(var.assigned_template[m], try(var.assigned_template["default"], "default"))],
#               # replace __default__ by abbreviations specific for resource
#               "__default__",
#               var.abbreviations[m]
#             ),
#             # replace __az_numeric__ with number for availability zone
#             "__az_numeric__",
#             try(var.az_map_literal_to_numeric[split(var.region, v)[1]], "")
#           ),
#           # replace __az_literal__ by letter for availability zone
#           "__az_literal__",
#           try(split(var.region, v)[1], "")
#         ),
#         # remove delimiter from the beginning and end of string (if required in some cases)
#       var.name_delimiter)
#     }
#   }
# }
