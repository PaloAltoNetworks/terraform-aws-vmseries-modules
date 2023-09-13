locals {
  name_template = {
    # for every kind of template
    for k, v in var.name_template : k => join(
      # use delimieter to concatenate all parts of name
      v.name_delimiter,
      # from template take all parts with 1 exception
      flatten([for part in v.parts : [
        for part_name, part_value in part : part_name == "prefix" ? var.name_prefix : part_value
      ]])
    )
  }
}