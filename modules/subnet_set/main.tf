locals {
  input_subnets = { for k, v in var.cidrs :
    v.az => {
      name                    = coalesce(try(v.name, null), "${var.name}${substr(v.az, -1, -1)}")
      cidr_block              = k
      create_subnet           = try(v.create_subnet, true)
      create_route_table      = try(v.create_route_table, v.create_subnet, true)
      read_route_table        = var.create_shared_route_table == false && try(v.create_route_table, v.create_subnet, true) == false
      existing_route_table_id = try(v.existing_route_table_id, null)
      associate_route_table   = try(v.associate_route_table, true)
      route_table_name        = try(v.route_table_name, null)
      local_tags              = try(v.local_tags, {})
    }
  }
  #
  # Convenient combined objects, each is either a `resource` object or a `data` object.
  #
  subnets      = { for k, v in local.input_subnets : k => v.create_subnet ? try(aws_subnet.this[k], null) : try(data.aws_subnet.this[k], null) }
  route_tables = { for k, v in local.input_subnets : k => v.read_route_table == false ? try(aws_route_table.this[k], null) : try(data.aws_route_table.this[k], null) }
}

#### Existing Subnets ####

data "aws_subnet" "this" {
  for_each = { for k, v in local.input_subnets : k => v if v.create_subnet == false }

  tags = { Name = each.value.name }
}

#### Create Subnets ####

resource "aws_subnet" "this" {
  for_each = { for k, v in local.input_subnets : k => v if v.create_subnet }

  cidr_block              = each.value.cidr_block
  availability_zone       = each.key
  vpc_id                  = var.vpc_id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = merge(var.global_tags, each.value.local_tags, { Name = each.value.name })
}

#### One route table per each subnet by default #### 

data "aws_route_table" "this" {
  for_each = { for k, v in local.input_subnets : k => v if v.read_route_table }

  vpc_id         = var.vpc_id
  route_table_id = each.value.existing_route_table_id
  tags           = { Name = coalesce(each.value.route_table_name, each.value.name) }
}

resource "aws_route_table" "this" {
  for_each = { for k, v in local.input_subnets : k => v if v.read_route_table == false && var.create_shared_route_table == false }

  vpc_id           = var.vpc_id
  tags             = merge(var.global_tags, each.value.local_tags, { Name = coalesce(each.value.route_table_name, each.value.name) })
  propagating_vgws = var.propagating_vgws
}

resource "aws_route_table" "shared" {
  for_each = { for _, v in local.input_subnets : "shared" => v... if v.read_route_table == false && var.create_shared_route_table }

  vpc_id           = var.vpc_id
  tags             = merge(var.global_tags, each.value[0].local_tags, { Name = each.value[0].route_table_name })
  propagating_vgws = var.propagating_vgws
}

resource "aws_route_table_association" "this" {
  for_each = { for k, v in local.input_subnets : k => v if v.associate_route_table }

  subnet_id      = local.subnets[each.key].id
  route_table_id = var.create_shared_route_table == false ? local.route_tables[each.key].id : aws_route_table.shared["shared"].id
}
