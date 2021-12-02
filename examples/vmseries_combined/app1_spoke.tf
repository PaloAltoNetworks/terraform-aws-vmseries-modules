module "app1_vpc" {
  source = "../../modules/vpc"

  name                    = var.app1_vpc_name
  cidr_block              = var.app1_vpc_cidr
  security_groups         = var.app1_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "app1_subnet_sets" {
  for_each = toset(distinct([for _, v in var.app1_vpc_subnets : v.set]))
  source   = "../../modules/subnet_set"

  name                = each.key
  vpc_id              = module.app1_vpc.id
  has_secondary_cidrs = module.app1_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.app1_vpc_subnets : k => v if v.set == each.key }
}

module "app1_transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  name                        = var.app1_transit_gateway_attachment_name
  vpc_id                      = module.app1_subnet_sets["app1_vm"].vpc_id
  subnets                     = module.app1_subnet_sets["app1_vm"].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables["from_spoke_vpc"]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables["from_security_vpc"].id
  }
}

module "app1_gwlbe_inbound" {
  source = "../../modules/gwlb_endpoint_set"

  name              = var.app1_gwlb_endpoint_set_name
  gwlb_service_name = coalesce(var.security_gwlb_service_name, module.security_gwlb.endpoint_service.service_name) # this is cross-vpc
  vpc_id            = module.app1_subnet_sets["app1_gwlbe"].vpc_id
  subnets           = module.app1_subnet_sets["app1_gwlbe"].subnets
  act_as_next_hop_for = {
    "from-igw-to-lb" = {
      route_table_id = module.app1_vpc.internet_gateway_route_table.id
      to_subnets     = module.app1_subnet_sets["app1_lb"].subnets
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table,
    # and AWS allows their destinations to only be:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table
  }
}

module "app1_route" {
  for_each = {
    from-gwlbe-to-igw = {
      next_hop_set    = module.app1_vpc.igw_as_next_hop_set
      route_table_ids = module.app1_subnet_sets["app1_gwlbe"].unique_route_table_ids
      to_cidr         = "0.0.0.0/0"
    }
    from-web-to-tgw = {
      next_hop_set    = module.app1_transit_gateway_attachment.next_hop_set
      route_table_ids = module.app1_subnet_sets["app1_vm"].unique_route_table_ids
      to_cidr         = "0.0.0.0/0"
    }
    from-lb-to-gwlbe = {
      next_hop_set    = module.app1_gwlbe_inbound.next_hop_set
      route_table_ids = module.app1_subnet_sets["app1_lb"].unique_route_table_ids
      to_cidr         = "0.0.0.0/0"
    }
  }
  source = "../../modules/vpc_route"

  route_table_ids = each.value.route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

### App1 EC2 instance ###

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

module "app1_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"

  name           = "app1"
  instance_count = 1

  ami                    = data.aws_ami.this.id
  instance_type          = "t3.micro"
  key_name               = local.key_name
  vpc_security_group_ids = [module.app1_vpc.security_group_ids["app1_vm"]]
  subnet_id              = module.app1_subnet_sets["app1_vm"].subnets[local.app1_az].id
  tags                   = var.global_tags
}

locals {
  # Just use a single virtual machine in a single AZ as a test box.
  app1_az = "${var.region}a"
  # Reuse the same key pair as for VMSeries instances.
  key_name = element(values(module.vmseries.firewalls), 0).key_name
}

resource "aws_eip" "lb" {
  vpc = true
}

### Inbound Load Balancer ###

# It is not for balancing the load per se, but rather as a route separation tool (as it introduces extra route tables).
module "app1_lb" {
  source = "terraform-aws-modules/alb/aws"
  # The name "alb" is a bit misleading as the module can deploy either ALB or NLB.
  # It means it can create a load balancer of type "application" (ALB) or "network" (NLB).
  version = "~> 6.5"

  name               = "lb1"
  load_balancer_type = "network"
  vpc_id             = module.app1_subnet_sets["app1_lb"].vpc_id
  subnet_mapping = [
    {
      allocation_id = aws_eip.lb.id
      subnet_id     = module.app1_subnet_sets["app1_lb"].subnets[local.app1_az].id
    }
  ]

  http_tcp_listeners = [
    {
      port               = 22
      protocol           = "TCP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name_prefix          = "tg0"
      backend_protocol     = "TCP"
      backend_port         = 22
      target_type          = "instance"
      deregistration_delay = 10
      targets = {
        my_ec2 = {
          target_id = try(module.app1_ec2.id[0], null)
          port      = 22
        }
      }
    }
  ]

  tags = var.global_tags

  depends_on = [
    # Workaround for error: VPC vpc-0123 has no internet gateway.
    module.app1_vpc
  ]
}
