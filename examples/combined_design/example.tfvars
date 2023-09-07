### GENERAL
region = "eu-central-1" # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

name_templates = {
  name_delimiter = "-"
  name_template = {
    default = [
      { prefix = "scz" },
      { abbreviation = "__default__" },
      { bu = "cloud" },
      { env = "tst" },
      { suffix = "ec1" },
    ]
    index = [
      { prefix = "scz" },
      { abbreviation = "__default__" },
      { bu = "cloud" },
      { env = "tst" },
      { suffix = "ec1" },
      { index = "%s" },
    ]
    name = [
      { prefix = "scz" },
      { abbreviation = "__default__" },
      { name = "%s" },
      { bu = "cloud" },
      { env = "tst" },
      { suffix = "ec1" },
    ]
    name_with_az = [
      { prefix = "scz" },
      { abbreviation = "__default__" },
      { name = "%s" },
      { bu = "cloud" },
      { env = "tst" },
      { suffix = "ec1" },
      { az = "__az_numeric__" }, # __az_literal__, __az_numeric__
    ]
  }
  assign_template = {
    default     = "name"
    subnet      = "name_with_az"
    nat_gateway = "index"
    vm          = "index"
    vmseries    = "index"
  }
  abbreviations = {
    vpc     = "vpc"
    igw     = "igw"
    vgw     = "vgw"
    snet    = "snet"
    rt      = "rt"
    ngw     = "ngw"
    tgw     = "tgw"
    tgw_att = "att"
    gwlb    = "gwlb"
    gwlb_tg = "gwtg"
    gwlb_ep = "gwep"
    vm      = "vm"
    alb     = "alb"
    alb_tg  = "atg"
    nlb     = "nlb"
    nlb_tg  = "ntg"
    role    = "role"
    profile = "profile"
  }
}

### VPC
vpcs = {
  # Do not use `-` in key for VPC as this character is used in concatation of VPC and subnet for module `subnet_set` in `main.tf`
  security_vpc = {
    name = "security"
    cidr = "10.100.0.0/16"
    nacls = {
      trusted_path_monitoring = {
        name = "trusted-path-monitoring"
        rules = {
          block_outbound_icmp_1 = {
            rule_number = 110
            egress      = true
            protocol    = "icmp"
            rule_action = "deny"
            cidr_block  = "10.100.1.0/24"
            from_port   = null
            to_port     = null
          }
          block_outbound_icmp_2 = {
            rule_number = 120
            egress      = true
            protocol    = "icmp"
            rule_action = "deny"
            cidr_block  = "10.100.65.0/24"
            from_port   = null
            to_port     = null
          }
          allow_other_outbound = {
            rule_number = 200
            egress      = true
            protocol    = "-1"
            rule_action = "allow"
            cidr_block  = "0.0.0.0/0"
            from_port   = null
            to_port     = null
          }
          allow_inbound = {
            rule_number = 300
            egress      = false
            protocol    = "-1"
            rule_action = "allow"
            cidr_block  = "0.0.0.0/0"
            from_port   = null
            to_port     = null
          }
        }
      }
    }
    security_groups = {
      vmseries_private = {
        name = "vmseries_private"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          geneve = {
            description = "Permit GENEVE to GWLB subnets"
            type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
            cidr_blocks = [
              "10.100.5.0/24", "10.100.69.0/24"
            ]
          }
          health_probe = {
            description = "Permit Port 80 Health Probe to GWLB subnets"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = [
              "10.100.5.0/24", "10.100.69.0/24"
            ]
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
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          panorama_ssh = {
            description = "Permit Panorama SSH (Optional)"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["10.0.0.0/8"]
          }
          panorama_mgmt = {
            description = "Permit Panorama Management"
            type        = "ingress", from_port = "3978", to_port = "3978", protocol = "tcp"
            cidr_blocks = ["10.0.0.0/8"]
          }
          panorama_log = {
            description = "Permit Panorama Logging"
            type        = "ingress", from_port = "28443", to_port = "28443", protocol = "tcp"
            cidr_blocks = ["10.0.0.0/8"]
          }
        }
      }
      vmseries_public = {
        name = "vmseries_public"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.100.0.0/24"  = { az = "eu-central-1a", set = "mgmt", nacl = null }
      "10.100.64.0/24" = { az = "eu-central-1b", set = "mgmt", nacl = null }
      "10.100.1.0/24"  = { az = "eu-central-1a", set = "private", nacl = "trusted_path_monitoring" }
      "10.100.65.0/24" = { az = "eu-central-1b", set = "private", nacl = "trusted_path_monitoring" }
      "10.100.2.0/24"  = { az = "eu-central-1a", set = "public", nacl = null }
      "10.100.66.0/24" = { az = "eu-central-1b", set = "public", nacl = null }
      "10.100.3.0/24"  = { az = "eu-central-1a", set = "tgw_attach", nacl = null }
      "10.100.67.0/24" = { az = "eu-central-1b", set = "tgw_attach", nacl = null }
      "10.100.4.0/24"  = { az = "eu-central-1a", set = "gwlbe_outbound", nacl = null }
      "10.100.68.0/24" = { az = "eu-central-1b", set = "gwlbe_outbound", nacl = null }
      "10.100.5.0/24"  = { az = "eu-central-1a", set = "gwlb", nacl = null }
      "10.100.69.0/24" = { az = "eu-central-1b", set = "gwlb", nacl = null }
      "10.100.10.0/24" = { az = "eu-central-1a", set = "gwlbe_eastwest", nacl = null }
      "10.100.74.0/24" = { az = "eu-central-1b", set = "gwlbe_eastwest", nacl = null }
      "10.100.11.0/24" = { az = "eu-central-1a", set = "natgw", nacl = null }
      "10.100.75.0/24" = { az = "eu-central-1b", set = "natgw", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_default = {
        vpc_subnet    = "security_vpc-mgmt"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      mgmt_panorama = {
        vpc_subnet    = "security_vpc-mgmt"
        to_cidr       = "10.255.0.0/16"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      mgmt_rfc1918 = {
        vpc_subnet    = "security_vpc-mgmt"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      tgw_rfc1918 = {
        vpc_subnet    = "security_vpc-tgw_attach"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_gwlb_eastwest"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_default = {
        vpc_subnet    = "security_vpc-tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_gwlb_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      # public_default = {
      #   vpc_subnet    = "security_vpc-public"
      #   to_cidr       = "0.0.0.0/0"
      #   next_hop_key  = "security_vpc"
      #   next_hop_type = "internet_gateway"
      # }
      public_default = {
        vpc_subnet    = "security_vpc-public"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_nat_gw"
        next_hop_type = "nat_gateway"
      }
      gwlbe_outbound_rfc1918 = {
        vpc_subnet    = "security_vpc-gwlbe_outbound"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_eastwest_rfc1918 = {
        vpc_subnet    = "security_vpc-gwlbe_eastwest"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      nat_default = {
        vpc_subnet    = "security_vpc-natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_rfc1918 = {
        vpc_subnet    = "security_vpc-natgw"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_gwlb_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  app1_vpc = {
    name  = "app1"
    cidr  = "10.104.0.0/16"
    nacls = {}
    security_groups = {
      app1_vm = {
        name = "app1_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
      app1_lb = {
        name = "app1_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.104.0.0/24"   = { az = "eu-central-1a", set = "app1_vm", nacl = null }
      "10.104.128.0/24" = { az = "eu-central-1b", set = "app1_vm", nacl = null }
      "10.104.2.0/24"   = { az = "eu-central-1a", set = "app1_lb", nacl = null }
      "10.104.130.0/24" = { az = "eu-central-1b", set = "app1_lb", nacl = null }
      "10.104.3.0/24"   = { az = "eu-central-1a", set = "app1_gwlbe", nacl = null }
      "10.104.131.0/24" = { az = "eu-central-1b", set = "app1_gwlbe", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc_subnet    = "app1_vpc-app1_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_default = {
        vpc_subnet    = "app1_vpc-app1_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc_subnet    = "app1_vpc-app1_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  app2_vpc = {
    name  = "app2"
    cidr  = "10.105.0.0/16"
    nacls = {}
    security_groups = {
      app2_vm = {
        name = "app2_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
      app2_lb = {
        name = "app2_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.105.0.0/24"   = { az = "eu-central-1a", set = "app2_vm", nacl = null }
      "10.105.128.0/24" = { az = "eu-central-1b", set = "app2_vm", nacl = null }
      "10.105.2.0/24"   = { az = "eu-central-1a", set = "app2_lb", nacl = null }
      "10.105.130.0/24" = { az = "eu-central-1b", set = "app2_lb", nacl = null }
      "10.105.3.0/24"   = { az = "eu-central-1a", set = "app2_gwlbe", nacl = null }
      "10.105.131.0/24" = { az = "eu-central-1b", set = "app2_gwlbe", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc_subnet    = "app2_vpc-app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_default = {
        vpc_subnet    = "app2_vpc-app2_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc_subnet    = "app2_vpc-app2_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
}

### TRANSIT GATEWAY
tgw = {
  create = true
  id     = null
  name   = "tgw"
  asn    = "64512"
  route_tables = {
    # Do not change keys `from_security_vpc` and `from_spoke_vpc` as they are used in `main.tf` and attachments
    "from_security_vpc" = {
      create = true
      name   = "from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
  attachments = {
    # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
    # Value of `route_table` and `propagate_routes_to` must match `route_tables` stores under `tgw`
    security = {
      name                = "vmseries"
      vpc_subnet          = "security_vpc-tgw_attach"
      route_table         = "from_security_vpc"
      propagate_routes_to = "from_spoke_vpc"
    }
    app1 = {
      name                = "app1"
      vpc_subnet          = "app1_vpc-app1_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
    app2 = {
      name                = "app2"
      vpc_subnet          = "app2_vpc-app2_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
  }
}

### NAT GATEWAY
natgws = {
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  security_nat_gw = {
    name       = "natgw"
    vpc_subnet = "security_vpc-natgw"
    nat_gateway_names = {
      "eu-central-1a" = "001"
      "eu-central-1b" = "002"
    }
  }
}

### GATEWAY LOADBALANCER
gwlbs = {
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  security_gwlb = {
    name       = "security"
    vpc_subnet = "security_vpc-gwlb"
  }
}
gwlb_endpoints = {
  # Value of `gwlb` must match key of objects stored in `gwlbs`
  # Value of `vpc` must match key of objects stored in `vpcs`
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  security_gwlb_eastwest = {
    name            = "eastwest"
    gwlb            = "security_gwlb"
    vpc             = "security_vpc"
    vpc_subnet      = "security_vpc-gwlbe_eastwest"
    act_as_next_hop = false
    to_vpc_subnets  = null
  }
  security_gwlb_outbound = {
    name            = "outbound"
    gwlb            = "security_gwlb"
    vpc             = "security_vpc"
    vpc_subnet      = "security_vpc-gwlbe_outbound"
    act_as_next_hop = false
    to_vpc_subnets  = null
  }
  app1_inbound = {
    name            = "app1"
    gwlb            = "security_gwlb"
    vpc             = "app1_vpc"
    vpc_subnet      = "app1_vpc-app1_gwlbe"
    act_as_next_hop = true
    to_vpc_subnets  = "app1_vpc-app1_lb"
  }
  app2_inbound = {
    name            = "app2"
    gwlb            = "security_gwlb"
    vpc             = "app2_vpc"
    vpc_subnet      = "app2_vpc-app2_gwlbe"
    act_as_next_hop = true
    to_vpc_subnets  = "app2_vpc-app2_lb"
  }
}

### VM-SERIES
vmseries = {
  ngfw = {
    instances = {
      "001" = { az = "eu-central-1a" }
      "002" = { az = "eu-central-1b" }
    }

    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
    bootstrap_options = {
      mgmt-interface-swap         = "enable"
      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable" # TODO: update here
      panorama-server             = "10.255.0.10"                                                                        # TODO: update here
      auth-key                    = ""                                                                                   # TODO: update here
      dgname                      = "combined"                                                                           # TODO: update here
      tplname                     = "combined-stack"                                                                     # TODO: update here
      dhcp-send-hostname          = "yes"                                                                                # TODO: update here
      dhcp-send-client-id         = "yes"                                                                                # TODO: update here
      dhcp-accept-server-hostname = "yes"                                                                                # TODO: update here
      dhcp-accept-server-domain   = "yes"                                                                                # TODO: update here
    }

    panos_version = "10.2.3"        # TODO: update here
    ebs_kms_id    = "alias/aws/ebs" # TODO: update here

    # Value of `vpc` must match key of objects stored in `vpcs`
    vpc = "security_vpc"

    # Value of `gwlb` must match key of objects stored in `gwlbs`
    gwlb = "security_gwlb"

    interfaces = {
      private = {
        device_index      = 0
        security_group    = "vmseries_private"
        vpc_subnet        = "security_vpc-private"
        create_public_ip  = false
        source_dest_check = false
      }
      mgmt = {
        device_index      = 1
        security_group    = "vmseries_mgmt"
        vpc_subnet        = "security_vpc-mgmt"
        create_public_ip  = true
        source_dest_check = true
      }
      public = {
        device_index   = 2
        security_group = "vmseries_public"
        vpc_subnet     = "security_vpc-public"
        # create_public_ip  = true
        create_public_ip  = false
        source_dest_check = false
      }
    }

    # Value of `gwlb_endpoint` must match key of objects stored in `gwlb_endpoints`
    subinterfaces = {
      inbound = {
        app1 = {
          gwlb_endpoint = "app1_inbound"
          subinterface  = "ethernet1/1.11"
        }
        app2 = {
          gwlb_endpoint = "app2_inbound"
          subinterface  = "ethernet1/1.12"
        }
      }
      outbound = {
        only_1_outbound = {
          gwlb_endpoint = "security_gwlb_outbound"
          subinterface  = "ethernet1/1.20"
        }
      }
      eastwest = {
        only_1_eastwest = {
          gwlb_endpoint = "security_gwlb_eastwest"
          subinterface  = "ethernet1/1.30"
        }
      }
    }

    system_services = {
      dns_primary = "4.2.2.2"      # TODO: update here
      dns_secondy = null           # TODO: update here
      ntp_primary = "pool.ntp.org" # TODO: update here
      ntp_secondy = null           # TODO: update here
    }

    application_lb = {
      name  = null
      rules = {}
    }
    network_lb = {
      name  = null
      rules = {}
    }
  }
}

### PANORAMA
panorama_attachment = {
  transit_gateway_attachment_id = null            # TODO: update here
  vpc_cidr                      = "10.255.0.0/24" # TODO: update here
}

### SPOKE VMS
spoke_vms = {
  "app1-001" = {
    az             = "eu-central-1a"
    vpc            = "app1_vpc"
    vpc_subnet     = "app1_vpc-app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app1-002" = {
    az             = "eu-central-1b"
    vpc            = "app1_vpc"
    vpc_subnet     = "app1_vpc-app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app2-001" = {
    az             = "eu-central-1a"
    vpc            = "app2_vpc"
    vpc_subnet     = "app2_vpc-app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
  "app2-002" = {
    az             = "eu-central-1b"
    vpc            = "app2_vpc"
    vpc_subnet     = "app2_vpc-app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
}

### SPOKE LOADBALANCERS
spoke_nlbs = {
  "app1" = {
    vpc_subnet = "app1_vpc-app1_lb"
    rules = {
      "ssh" = {
        protocol    = "TCP"
        port        = "22"
        target_type = "instance"
        stickiness  = true
      }
    }
    vms = ["app1-001", "app1-002"]
  }
  "app2" = {
    vpc_subnet = "app2_vpc-app2_lb"
    rules = {
      "ssh" = {
        protocol    = "TCP"
        port        = "22"
        target_type = "instance"
        stickiness  = true
      }
    }
    vms = ["app2-001", "app2-002"]
  }
}

spoke_albs = {
  "app1" = {
    vms = ["app1-001", "app1-002"]
    rules = {
      "http" = {
        protocol              = "HTTP"
        port                  = 80
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
    vpc             = "app1_vpc"
    vpc_subnet      = "app1_vpc-app1_lb"
    security_groups = "app1_lb"
  }
  "app2" = {
    vms = ["app2-001", "app2-002"]
    rules = {
      "http" = {
        protocol              = "HTTP"
        port                  = 80
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
    vpc             = "app2_vpc"
    vpc_subnet      = "app2_vpc-app2_lb"
    security_groups = "app2_lb"
  }
}