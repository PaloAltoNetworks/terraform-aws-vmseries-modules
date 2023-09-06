locals {
  name_template = {
    for k, v in var.name_template : k => join(
      var.name_delimiter,
      flatten(
        [for v in var.name_template[k] : [
          for _, name_v in v : name_v if name_v != ""
        ]]
      )
    )
  }
}