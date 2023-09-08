variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}

variable "name_delimiter" {
  description = <<-EOF
  It specifies the delimiter used between all components of the new name.
  EOF
  type        = string
  default     = "-"
}

variable "name_prefix" {
  description = "Prefix used in names for the resources"
  type        = string
}

variable "name_template" {
  description = <<-EOF
  A list of maps, where keys are informational only.

  Important:
  1. elementy with key prefix (value is not important) will be replace by value of variable name_prefix
  2. %s will be eventually replaced by resource name
  3. __default__ is a marker that we will replace with a default resource abbreviation, anything else will be used literally.
  4. __az_numeric__ is a marker that we will replace letter from availability zone into number (e.g. a->1, b->2, ...)
  5. __az_literal__ is a marker that we will put letter for availability zone (e.g. for eu-central-1a it's going to be a)
  6. order matters

  Example:

  name_template = {
    name_at_the_end = [
      { prefix = null },
      { abbreviation = "__default__" },
      { bu = "cloud" },
      { env = "tst" },
      { suffix = "ec1" },
      { name = "%s" },
    ]
    name_with_az = [
      { prefix = null },
      { abbreviation = "__default__" },
      { name = "%s" },
      { bu = "cloud" },
      { env = "tst" },
      { suffix = "ec1" },
      { az = "__az_numeric__" },
    ]
  }

  EOF
  type        = map(list(map(string)))
  default     = {}
}

variable "names" {
  description = <<-EOF
  Map of objects defining template and names used for resources.

  Example:

  names = {
    vpc = {
      template = lookup(var.name_templates.assign_template, "vpc", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.vpcs : k => v.name }
    }
    gateway_loadbalancer = {
      template = lookup(var.name_templates.assign_template, "gateway_loadbalancer", lookup(var.name_templates.assign_template, "default", "default")),
      values   = { for k, v in var.gwlbs : k => v.name }
    }
  }

  Please take a look combined_design example, which contains full map for names.

  EOF
  type = map(object({
    template : string
    values : map(string)
  }))
  default = {}
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
    route_table                           = "rt"
    nat_gateway                           = "ngw"
    transit_gateway                       = "tgw"
    transit_gateway_attachment            = "att"
    gateway_loadbalancer                  = "gwlb"
    gateway_loadbalancer_target_group     = "gwtg"
    gateway_loadbalancer_endpoint         = "gwep"
    vm                                    = "vm"
    vmseries                              = "vm"
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