locals {
  delimiter      = var.name_template["delimiter"]
  template_parts = var.name_template["parts"]
  template_unabbreviated = join(
    local.delimiter,
    flatten([for part in local.template_parts : [
      for part_name, part_value in part : part_name == "prefix" ? var.name_prefix : part_value
    ]])
  )
  resource_name = replace(local.template_unabbreviated, "__default__", var.abbreviations[var.resource_type])
}