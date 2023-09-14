locals {
  name_templates = {
    # for every kind of template
    for k, v in var.name_templates : k => join(
      # use delimieter to concatenate all parts of name
      var.name_templates[k].delimiter,
      # from template take all parts with 1 exception
      flatten(
        [for v in var.name_templates[k].parts : [
          # if part is named prefix, then use value of prefix from dedicated variable (introduced because of 2 reasons)
          # - to not to repeat the same prefix in multiple templats
          # - to make Terratest work correctly (we cannot pass a map as vars, it has to be string)
          for i, j in v : i == "prefix" ? var.name_prefix : j
        ]]
      )
    )
  }

  name_template = try(
    join(
      # use delimieter to concatenate all parts of name
      var.name_template.delimiter,
      # from template take all parts with 1 exception
      flatten([for v in var.name_template.parts : [
        # if part is named prefix, then use value of prefix from dedicated variable (introduced because of 2 reasons)
        # - to not to repeat the same prefix in multiple templats
        # - to make Terratest work correctly (we cannot pass a map as vars, it has to be string)
        for i, j in v : i == "prefix" ? var.name_prefix : j
      ]])
    ),
  null)
}