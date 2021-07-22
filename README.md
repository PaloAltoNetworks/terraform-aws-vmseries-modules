Gallery (https://gallery.pan.dev/) is a separate forum used to appropriately structure and organize repositories. 
Easier method of searching Repositories and maintaining each Repository.

Following Repository is also available in (https://gallery.pan.dev/).
[terraform-aws-vmseries-modules/modules/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules)

[terraform-aws-vmseries-modules/modules/bootstrap/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/bootstrap) This Terraform Module creates a PAN-OS bootstrap package in an AWS S3 bucket to be used for bootstrapping Palo Alto Networks VM-Series virtual firewall instances. 

[terraform-aws-vmseries-modules/modules/crosszone_failover/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/crosszone_failover)

[terraform-aws-vmseries-modules/modules/gwlb/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/gwlb)

[terraform-aws-vmseries-modules/modules/transit_gateway/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/transit_gateway) Module for interactions with Transit Gateways for VM-Series deployments.

[terraform-aws-vmseries-modules/modules/vmseries/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/vmseries)

[terraform-aws-vmseries-modules/modules/vpc/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/vpc)

[terraform-aws-vmseries-modules/modules/vpc_routes/](https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/tree/develop/modules/vpc_routes)








# Terraform Modules for Palo Alto Networks VM-Series on AWS

## Overview

A set of modules for using **Palo Alto Networks VM-Series firewalls** to provide control and protection
to your applications running in Amazon Web Services (AWS). It deploys VM-Series as virtual machine
instances and it configures aspects such as Transit Gateway connectivity, VPCs, IAM access, Panorama virtual
machine instances, and more.

The design is heavily based on the [AWS Reference Architecture Guide](https://pandocs.tech/fw/110p-prime).

For copyright and license see the LICENSE file.

## Structure

This repository has the following directory structure:

* [modules](./modules): This directory contains several standalone, reusable, production-grade Terraform modules. Each module is individually documented.
* [examples](./examples): This directory shows examples of different ways to combine the modules contained in the
  `modules` directory.

## Compatibility

The compatibility with Terraform is defined individually per each module. In general, expect the earliest compatible
Terraform version to be 0.12.29 across most of the modules.
<!-- [FUTURE] If you need to stay on Terraform 0.12.29 and need to use these modules, the recommended last compatible release is 1.2.3. -->

## Versioning

These modules follow the principles of [Semantic Versioning](http://semver.org/). You can find each new release,
along with the changelog, on the GitHub [Releases](../../releases) page.

## Getting Help

[Open an issue](../../issues) on Github.

## Contributing

Contributions are welcome, and they are greatly appreciated! Every little bit helps,
and credit will always be given. Please follow our [contributing guide](./docs/contributing.md).

<!-- ## Who maintains these modules?

This repository is maintained by [Palo Alto Networks](https://www.paloaltonetworks.com/).
If you're looking for commercial support or services, send an email to [address not known yet]. -->
