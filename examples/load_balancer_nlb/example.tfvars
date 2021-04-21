### Global
region          = "us-east-1"
prefix_name_tag = "kbechler-"
global_tags = {
  managed-by = "Terraform"
}



### VPC
vpc = {
  vpc01 = {
    name             = "bar"
    cidr_block       = "172.18.0.0/16"
    internet_gateway = true
  }
}

subnets = {
  private-1a = { name = "private-1a", cidr = "172.18.21.0/24", az = "us-east-1a", rt = "private" }
  private-1b = { name = "private-1b", cidr = "172.18.22.0/24", az = "us-east-1b", rt = "private" }
}

route_tables = {
  private = { name = "private" }
}

security_groups = {
  sg1 = {
    name = "kbechler-sg1"
    rules = {
      all-outbound = {
        description = "Permit All traffic outbound"
        type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ssh-inbound = {
        description = "Permit SSH inbound"
        type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}

routes = {
  mgmt-igw = {
    route_table   = "private"
    prefix        = "0.0.0.0/0"
    next_hop_type = "internet_gateway"
    next_hop_name = "vpc01"
  }
}



### LOAD BALANCER
nlbs = {
  nlb01 = {
    name                             = "nlb01-inbound"
    internal                         = false
    eips                             = true
    enable_cross_zone_load_balancing = true
    apps = {
      app01 = {
        name          = "inbound-nlb01-app01-ssh"
        protocol      = "TCP"
        listener_port = "22"
        target_port   = "22"
      }
    }
  }
}
