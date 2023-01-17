global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW Automatic Tests"
}
region      = "us-east-1"
name_prefix = "test-vpc-route-"

security_vpc_cidr = "10.100.0.0/16"
security_vpc_subnets = {
  "10.100.0.0/24" = { az = "us-east-1a", set = "app_vm" }
  "10.100.2.0/24" = { az = "us-east-1b", set = "app_vm" }
  "10.100.3.0/24" = { az = "us-east-1a", set = "app_lb" }
  "10.100.4.0/24" = { az = "us-east-1b", set = "app_lb" }
}
security_vpc_security_groups = {
  app_vm = {
    name = "app_vm"
    rules = {
      all_outbound = {
        description = "Permit ALL outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh = {
        description = "Permit SSH inbound"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}

app_vms = {
  "app_vm01" = { az = "us-east-1a" }
  "app_vm02" = { az = "us-east-1b" }
}

application_lb_rules = {
  "main-welcome-page" = {
    protocol              = "HTTP"
    health_check_port     = "80"
    health_check_matcher  = "200"
    health_check_path     = "/"
    health_check_interval = 10
    listener_rules = {
      "1" = {
        target_protocol = "HTTP"
        target_port     = 80
        path_pattern    = ["/"]
      }
    }
  }
}