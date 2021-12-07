# copy pasted from examples/single_vpc

# Experiment with brownfield EIPs

resource "aws_eip" "brownnatgw_a" {
  tags = { Name = "jb14" }
}

resource "aws_eip" "brownnatgw_b" {}

module "brownnatgw_set" {
  source = "../../modules/nat_gateway_set"

  create_eip = false # create nat gateway, but on pre-existing public IP addresses
  subnets    = module.subnet_sets["mgmt-1"].subnets
  eips = {
    "us-east-1a" = { name = aws_eip.brownnatgw_a.tags.Name }
    "us-east-1b" = { id = aws_eip.brownnatgw_b.id }
  }
  global_tags = { Team = "A-Team" }
}

output "brownnatgw_set_next_hop_set" {
  value = module.brownnatgw_set.next_hop_set
}

module "natgw_set_read" {
  source = "../../modules/nat_gateway_set"

  create_nat_gateway = false
  subnets            = module.subnet_sets["mgmt-1"].subnets
  # nat_gateway_names = {
  #   "us-east-1a" = "mgmt-1a"
  #   "us-east-1b" = "mgmt-1b"
  # }
  # nat_gateway_tags = { Team = "A-Team" }
}

output "natgw_set_read_next_hop_set" {
  value = module.natgw_set_read.next_hop_set
}
