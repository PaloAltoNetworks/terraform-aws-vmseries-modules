# COMMON VARIABLES
global_tags = {
  ManagedBy   = "Terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
}


# SECURITY VPC CONFIGURATION
security_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.100.0.0/24"  = { az = "us-east-1a", set = "mgmt" }
  "10.100.1.0/24"  = { az = "us-east-1a", set = "trust" }
  "10.100.2.0/24"  = { az = "us-east-1a", set = "untrust" }
  "10.100.3.0/24"  = { az = "us-east-1a", set = "tgw" }
  "10.100.10.0/24" = { az = "us-east-1b", set = "mgmt" }
  "10.100.11.0/24" = { az = "us-east-1b", set = "trust" }
  "10.100.12.0/24" = { az = "us-east-1b", set = "untrust" }
  "10.100.13.0/24" = { az = "us-east-1b", set = "tgw" }
}

security_vpc_security_groups = {
  application_load_balancer = {
    name = "alb"
    rules = {
      all_inbound = {
        description = "Permit incoming traffic"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "TCP"
        cidr_blocks = ["0.0.0.0/32"] # <- TODO: modify allowed inbound traffic
      }
      fw_traffic = {
        description = "Permit traffic to FW subnets only"
        type        = "egress", from_port = "0", to_port = "65535", protocol = "TCP"
        cidr_blocks = ["10.100.2.0/24", "10.100.12.0/24"]
      }
    }
  }
  
  netowork_load_balancer = {
    name = "nlb"
    rules = {
      all_inbound = {
        description = "Permit incoming traffic"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "TCP"
        cidr_blocks = ["0.0.0.0/32"] # <- TODO: modify allowed inbound traffic
      }
      fw_traffic = {
        description = "Permit traffic to FW subnets only"
        type        = "egress", from_port = "0", to_port = "65535", protocol = "TCP"
        cidr_blocks = ["10.100.2.0/24", "10.100.12.0/24"]
      }
    }
  }
  vmseries_mgmt = {
    name = "vmseries_mgmt"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        description = "Permit HTTPS"
        type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/32"] # <- TODO: modify allowed inbound traffic
      }
      ssh = {
        description = "Permit SSH"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/32"] # <- TODO: modify allowed inbound traffic
      }
    }
  }
  vmseries_trust = {
    name = "vmseries_trust"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound to VPCs only"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16"]
      }
      https = {
        description = "Permit All traffic inbound from VPCs only"
        type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16"]
      }
    }
  }
  vmseries_untrust = {
    name = "vmseries_untrust"
    rules = {
      all_outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      health_check = {
        description = "Health check traffic from Load Balancer"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "TCP"
        cidr_blocks = ["10.100.2.0/24", "10.100.12.0/24"]
      }
      https = {
        description = "Permit http traffic inbound from LB only"
        type        = "ingress", from_port = "8080", to_port = "8080", protocol = "TCP"
        cidr_blocks = ["10.100.2.0/24", "10.100.12.0/24"]
      }
      ssh = {
        description = "Permit SSH traffic inbound from LB only"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "TCP"
        cidr_blocks = ["10.100.2.0/24", "10.100.12.0/24"]
      }
    }
  }
}


# VMSERIES CONFIGURATION
vmseries = {
  vmseries01 = { az = "us-east-1a" }
  vmseries02 = { az = "us-east-1b" }
}
vmseries_version = "10.2.1"
# ssh_key_name      = "public ssh key"
bootstrap_options = "type=dhcp-client"


# CONFIGURATION OF LOAD BALANCERS IN FRONT OF THE FIREWALLS
network_lb_rules = {
  "mqtt-traffic" = {
    protocol          = "TCP"
    port              = "22"
    health_check_port = "80"
    threshold         = 2
    interval          = 10
    stickiness        = true
  }
}
application_lb_rules = {
  "main-welcome-page" = {
    protocol              = "HTTP"
    health_check_port     = "80"
    health_check_matcher  = "302"
    health_check_path     = "/"
    health_check_interval = 10
    listener_rules = {
      "1" = {
        target_protocol = "HTTP"
        target_port     = 8080
        host_headers    = ["example-page.com", "www.example-page.com"]
      }
    }
  }
}


# APPLICATION VPC CONFIGURATION
app_vpc_subnets = {
  # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
  "10.200.0.0/24" = { az = "us-east-1a", set = "appl" }
  "10.200.1.0/24" = { az = "us-east-1a", set = "tgw" }
  "10.200.2.0/24" = { az = "us-east-1b", set = "appl" }
  "10.200.3.0/24" = { az = "us-east-1b", set = "tgw" }
}
app_vpc_security_groups = {
  app_example = {
    name = "app-example"
    rules = {
      http_inbound = {
        description = "Permit http incoming traffic"
        type        = "ingress", from_port = "80", to_port = "80", protocol = "TCP"
        cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16"]
      }
      ssh_inbound = {
        description = "Permit SSH incoming traffic"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "TCP"
        cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16"]
      }
      to_fw_traffic = {
        description = "Permit all  traffic to FW"
        type        = "egress", from_port = "0", to_port = "0", protocol = "ALL"
        cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16"]
      }
    }
  }
}


# APPLICATION INFRASTRUCTURE CONFIGURATION
app_vms = {
  "appvm01" = { az = "us-east-1b" }
  "appvm02" = { az = "us-east-1a" }
}
app_lb_rules = {
  "ssh-traffic" = {
    protocol   = "TCP"
    port       = "22"
    threshold  = 2
    interval   = 10
    stickiness = true
  }
  "http-traffic" = {
    protocol   = "TCP"
    port       = "80"
    threshold  = 2
    interval   = 10
    stickiness = true
  }
}


# TRANSIT GATEWAY CONFIGURATION
transit_gateway_route_tables = {
  "security_vpc" = {
    create = true
    name   = "security"
  }
  "spokes_vpc" = {
    create = true
    name   = "spokes"
  }
}
