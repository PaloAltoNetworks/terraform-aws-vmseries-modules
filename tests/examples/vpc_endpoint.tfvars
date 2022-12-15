region = "us-east-1"

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series Combined"
  Owner       = "PS team"
  Creator     = "login"
}


security_vpc_name = "security-vpc-terratest"
security_vpc_cidr = "10.100.0.0/16"

