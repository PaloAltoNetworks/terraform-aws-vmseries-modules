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

variable "name_template" {
  description = <<-EOF
  A list of maps, where keys are informational only.

  Important:
  1. %s will be eventually replaced by resource name
  2. __default__ is a marker that we will replace with a default resource abbreviation, anything else will be used literally.
  3. order matters

  EOF
  type        = map(list(map(string)))
  default     = {}
}

variable "names" {
  description = <<-EOF
  Map of names used for resources (placed in place of "%s").
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
    vpc     = "vpc"
    snet    = "snet"
    rt      = "rt"
    ngw     = "ngw"
    tgw     = "tgw"
    tgw_att = "att"
    gwlb    = "gwlb"
    gwlb_ep = "gwep"
    vm      = "vm"
    alb     = "alb"
    nlb     = "nlb"
    role    = "role"
    profile = "profile"
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