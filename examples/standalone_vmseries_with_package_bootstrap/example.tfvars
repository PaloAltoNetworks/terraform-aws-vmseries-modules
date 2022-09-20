region      = "us-east-1"
name_prefix = "example-" # please change before running Terraform apply

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

create_iam_role_policy = true
iam_role_name          = "" #  if create_iam_role_policy==false, then please put IAM role name