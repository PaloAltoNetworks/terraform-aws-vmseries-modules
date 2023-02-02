output "generated_vpc_name" {
  value = local.vpc_name
}

output "vpc_cidr_block_correct" {
  value = module.vpc.vpc.cidr_block
}

output "is_vpc_name_correct" {
  value = (module.vpc.name == local.vpc_name)
}

output "vpc_read_cidr_block_correct" {
  value = module.vpc_read.vpc.cidr_block
}

output "is_vpc_read_name_correct" {
  value = (module.vpc_read.name == local.vpc_name)
}

output "vpc_read_igw_create_cidr_block_correct" {
  value = module.vpc_read_igw_create.vpc.cidr_block
}

output "is_vpc_read_igw_create_name_correct" {
  value = (module.vpc_read_igw_create.name == local.vpc_name)
}

output "vpc_read_igw_read_cidr_block_correct" {
  value = module.vpc_read_igw_read.vpc.cidr_block
}

output "is_vpc_read_igw_read_name_correct" {
  value = (module.vpc_read_igw_read.name == local.vpc_name)
}
