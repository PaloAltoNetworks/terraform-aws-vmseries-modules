variable region {
  description = "AWS region to use for the created resources"
  default     = null
  type        = string
}

variable switchme {
  description = "The true/false switch for testing the modifiability. Initial runs should use `true`, then at some point one or more consecutive runs should use `false` instead."
  type        = bool
}

module "bootstrap" {
  source      = "../../modules/bootstrap"
  prefix      = "a"
  global_tags = var.switchme ? {} : { switchme = var.switchme }
}

output bucket_name_correct {
  value = (substr(module.bootstrap.bucket_name, 0, 2) == "a-")
}

output instance_profile_name_correct {
  value = (substr(module.bootstrap.instance_profile_name, 0, 2) == "a-")
}
