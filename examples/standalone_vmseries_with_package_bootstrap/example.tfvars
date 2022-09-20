region      = "us-east-1"
name_prefix = "sczech-"

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
  Creator     = "sczech"
}

create_iam_role_policy = false
iam_role_name          = "sczech-bootstrap-role-test"