locals {
  name_template = {
    for k, v in var.name_template : k => join(
      var.name_delimiter,
      flatten(
        [for v in var.name_template[k] : [
          for i, j in v : i == "prefix" ? var.name_prefix : j
        ]]
      )
    )
  }
}