# Palo Alto Networks VM-Series NGFW Module Example for AWS Cloud

A Terraform module example allowing to deploy two instances of the Palo Alto Networks VM-Series NGFW combined with a [Gateway Load Balancer](https://aws.amazon.com/elasticloadbalancing/gateway-load-balancer/#:~:text=Gateway%20Load%20Balancer%20helps%20you,or%20down%2C%20based%20on%20demand.) and a [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) in AWS Cloud.

**NOTE:**
The Security Group attached to the Management interface uses an inbound rule allowing traffic to port `22` and `443` from `0.0.0.0/0`, which means that SSH and HTTP access to the NFGW is possible from all over the Internet. You should update the Security Group rules and limit access to the Management interface, for example - to only the public IP address from which you will connect to VM-Series.

## Usage

Create a `terraform.tfvars` file and copy the content of `example.tfvars` into it, adjust if needed.

Then execute:

```sh
terraform init
terraform apply
terraform output -json mgmt_eip
```

Connect through SSH to the VM-Series Management interface IP address using the SSH key you provided as the  `ssh_key_name` parameter in your `terraform.tfvars` file:

```sh
ssh <username>@<mgmt_eip> -i <path_to_your_private_ssh_key>
```

## Cleanup

To delete all the resources created by the previous `apply` attempts, execute:

```sh
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

## Modules

## Resources

## Inputs

## Outputs

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->