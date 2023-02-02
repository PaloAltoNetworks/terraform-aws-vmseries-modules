resource "aws_iam_role" "simulate_existing_role_for_test" {
  count = length(var.iam_role_name) > 0 ? 1 : 0

  name = var.iam_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

module "bootstrap" {
  source                      = "../../modules/bootstrap"
  prefix                      = "a"
  global_tags                 = { ManagedBy = "Terraform" }
  create_iam_role_policy      = var.create_iam_role_policy
  iam_role_name               = try(var.iam_role_name, "")
  dhcp_send_hostname          = var.dhcp_send_hostname
  dhcp_send_client_id         = var.dhcp_send_client_id
  dhcp_accept_server_hostname = var.dhcp_accept_server_hostname
  dhcp_accept_server_domain   = var.dhcp_accept_server_domain
  depends_on = [
    aws_iam_role.simulate_existing_role_for_test
  ]
}
