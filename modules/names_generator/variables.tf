variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in names for the resources"
  type        = string
}

variable "name_templates" {
  description = <<-EOF
  Map of templates used to generate names. Each template is defined by list of objects. Each object contains 1 element defined by key and string value.

  Important:
  0. Delimiter specifies the delimiter used between all components of the new name.
  1. Elements with key `prefix` (value is not important) will be replaced with value of the `name_prefix` variable (e.g. `{ prefix = null }`)
  2. `%s` will be eventually replaced by resource name
  3. `__default__` is a marker that we will be replaced with a default resource abbreviation, anything else will be used literally.
  4. `__az_numeric__` is a marker that will be used to replace the availability zone letter indicator with a number (e.g. a->1, b->2, ...)
  5. `__az_literal__` is a marker that will be used to replace the full availability zone name with a letter (e.g. `eu-central-1a` will become `a`)
  6. Order matters

  Example:

  name_template = {
    name_at_the_end = {
      delimiter = "-"
      parts = [
        { prefix = null },
        { abbreviation = "__default__" },
        { bu = "cloud" },
        { env = "tst" },
        { suffix = "ec1" },
        { name = "%s" },
    ] }
    name_after_abbr = {
      delimiter = "-"
      parts = [
        { prefix = null },
        { abbreviation = "__default__" },
        { name = "%s" },
        { bu = "cloud" },
        { env = "tst" },
        { suffix = "ec1" },
    ] }
    name_with_az = {
      delimiter = "-"
      parts = [
        { prefix = null },
        { abbreviation = "__default__" },
        { name = "%s" },
        { bu = "cloud" },
        { env = "tst" },
        { suffix = "ec1" },
        { az = "__az_numeric__" }, # __az_literal__, __az_numeric__
    ] }
    name_max_32_characters = {
      delimiter = "-"
      parts = [
        { prefix = null },
        { abbreviation = "__default__" },
        { name = "%s" },
        { bu = "cloud" },
        { env = "tst" },
    ] }
  }

  EOF
  type = map(object({
    delimiter = string
    parts     = list(map(string))
  }))
  default = {}
}

variable "template_assignments" {
  description = <<-EOF
  Map of templates (used to generate names) assigned to each kind of resource.

  Example:

  template_assignments = {
    default                               = "name_after_abbr"
    subnet                                = "name_with_az"
    route_table                           = "name_with_az"
    nat_gateway                           = "name_at_the_end"
    vm                                    = "name_at_the_end"
    vmseries                              = "name_at_the_end"
    vmseries_network_interface            = "name_at_the_end"
    application_loadbalancer              = "name_max_32_characters"
    application_loadbalancer_target_group = "name_max_32_characters"
    network_loadbalancer                  = "name_max_32_characters"
    network_loadbalancer_target_group     = "name_max_32_characters"
    gateway_loadbalancer                  = "name_max_32_characters"
    gateway_loadbalancer_target_group     = "name_max_32_characters"
  }

  EOF

  type    = map(string)
  default = {}
}

variable "names" {
  description = <<-EOF
  Map of objects defining names used for resources.

  Example:

  names = {
    vpc                           = { for k, v in var.vpcs : k => v.name }
    gateway_loadbalancer          = { for k, v in var.gwlbs : k => v.name }
    gateway_loadbalancer_endpoint = { for k, v in var.gwlb_endpoints : k => v.name }
  }

  Please take a look combined_design example, which contains full map for names.

  EOF
  type        = map(map(string))
  default     = {}
}

variable "abbreviations" {
  description = <<-EOF
  Map of abbreviations used for resources (placed in place of "__default__").
  EOF
  type        = map(string)
  default = {
    vpc                                   = "vpc"
    internet_gateway                      = "igw"
    vpn_gateway                           = "vgw"
    subnet                                = "snet"
    security_group                        = "sg"
    route_table                           = "rt"
    route_table_internet_gateway          = "rt"
    nat_gateway                           = "ngw"
    transit_gateway                       = "tgw"
    transit_gateway_route_table           = "trt"
    transit_gateway_attachment            = "att"
    gateway_loadbalancer                  = "gwlb"
    gateway_loadbalancer_target_group     = "gwtg"
    gateway_loadbalancer_endpoint         = "gwep"
    vm                                    = "vm"
    vmseries                              = "vm"
    vmseries_network_interface            = "nic"
    application_loadbalancer              = "alb"
    application_loadbalancer_target_group = "atg"
    network_loadbalancer                  = "nlb"
    network_loadbalancer_target_group     = "ntg"
    iam_role                              = "role"
    iam_instance_profile                  = "profile"
  }
}

variable "az_map_literal_to_numeric" {
  description = <<-EOF
  Map of number used instead of letters for AZs (placed in place of "__az_numeric__").
  EOF
  type        = map(string)
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
    g = 7
    h = 8
    i = 9
  }
}