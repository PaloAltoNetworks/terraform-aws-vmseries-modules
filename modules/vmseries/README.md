# vmseries

Terraform Module: PAN-OS firewall connecting two AWS subnets.

This Terraform module creates a PAN-OS firewall between a public and a private
subnet in an AWS VPC.  The configuration is based off of the
[AWS Deployment Guide - Single VPC Model](https://www.paloaltonetworks.com/apps/pan/public/downloadResource?pagePath=/content/pan/en_US/resources/guides/aws-deployment-guide-single-resource)
reference architecture.

## Usage

Include in a Terraform plan (see [PaloAltoNetworks/terraform-aws-panos-bootstrap](https://github.com/PaloAltoNetworks/terraform-aws-panos-bootstrap) for easy bootstrapping):

```terraform
module "firewall" {
  source  = "mrichardson03/panos-firewall/aws"

  vpc_id   = module.vpc.vpc_id
  key_name = var.key_name

  mgmt_subnet_id = module.vpc.mgmt_a_id
  mgmt_sg_id     = module.vpc.mgmt_sg_id
  mgmt_ip        = "10.1.9.21"

  eth1_subnet_id = module.vpc.public_a_id
  eth1_sg_id     = module.vpc.public_sg_id
  eth1_ip        = "10.1.10.10"

  eth2_subnet_id = module.vpc.web_a_id
  eth2_sg_id     = module.vpc.internal_sg_id
  eth2_ip        = "10.1.1.10"

  iam_instance_profile = module.bootstrap.instance_profile_name
  bootstrap_bucket     = module.bootstrap.bucket_name
}
```

### Required Inputs

`vpc_id`: VPC ID to create firewall instance in.

`key_name`: Key pair name to provision instances with.

`mgmt_subnet_id`: Subnet ID for firewall management interface.

`mgmt_ip`: Internal IP address for firewall management interface.

`mgmt_sg_id`: Security group ID for firewall management interface.

`eth1_subnet_id`: Subnet ID for firewall ethernet1/1 interface.

`eth1_ip`: Internal IP address for firewall ethernet1/1 interface.

`eth1_sg_id`: Security group ID for firewall ethernet1/1 interface.

`eth2_subnet_id`: Subnet ID for firewall ethernet1/2 interface.

`eth2_ip`: Internal IP address for firewall ethernet1/2 interface.

`eth2_sg_id`: Security group ID for firewall ethernet1/2 interface.

### Optional Inputs

`ami`: Firewall AMI to deploy.  If not specified, AMI will be looked up based
on the variables `panos_version` and `panos_license_type`.

`instance_type`: Instance type for firewall.  Default is m4.xlarge.

`iam_instance_profile`: IAM Instance Profile used to bootstrap firewall.

`bootstrap_bucket`: S3 bucket containing bootstrap configuration.

`create_mgmt_eip`: Create and assign elastic IP to management interface.

`create_eth1_eip`: Create and assign elastic IP to ethernet1/1 interface.

`tags`: A map of tags to add to all resources.

`panos_version`: PAN-OS version to deploy when looking up the AMI.  This can be
a PAN-OS release (e.g. `9.1`) which will look up the most recent AMI for that
release, or can be a specific version if an AMI exists for it (e.g. `9.1.0-h3`).

`panos_license_type`: PAN-OS license type (can be one of `byol`, `bundle1`,
`bundle2`).  Default is `byol`.

### Outputs

`instance_id`: Instance ID of created firewall.

`mgmt_public_ip`: Public IP address of firewall management interface (if any).

`mgmt_interface_id`: Interface ID of created firewall management interface.

`eth1_public_ip`: Public IP address of firewall ethernet1/1 interface (if any).

`eth1_interface_id`: Interface ID of created firewall ethernet1/1 interface.

`eth2_interface_id`: Interface ID of created firewall ethernet1/2 interface.
