# data "aws_ami" "ubuntu" {
#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   owners = ["099720109477"] # Canonical
# }

# resource "aws_eip" "app_eip" {
#   tags = merge({ Name = "fosix_eip_app" }, var.global_tags)
# }

# resource "aws_network_interface" "app_nic" {
#   subnet_id       = module.security_subnet_sets["trust"].subnets["eu-west-1a"].id
#   security_groups = [module.security_vpc.security_group_ids["vmseries_trust"]]
#   tags            = merge({ Name = "fosix_nic_app" }, var.global_tags)
# }

# # resource "aws_eip_association" "nic_eip" {
# #   allocation_id        = aws_eip.app_eip.allocation_id
# #   network_interface_id = aws_network_interface.app_nic.id

# #   # depends_on = [
# #   #   # Workaround for:
# #   #   # Error associating EIP: IncorrectInstanceState: The pending-instance-creation instance to which 'eni' is attached is not in a valid state for this operation
# #   #   aws_instance.this
# #   # ]
# # }

# resource "aws_instance" "app_vm" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.micro"
#   tags          = merge({ Name = "fosix_app_vm" }, var.global_tags)
#   key_name      = var.ssh_key_name

#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.app_nic.id
#   }
# }

# output "app_vm_ips" {
#   value = {
#     public  = aws_instance.app_vm.public_ip
#     private = aws_instance.app_vm.private_ip
#   }
# }
