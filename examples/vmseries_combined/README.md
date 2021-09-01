# VM-Series in the Centralized Design Combined Inbound Architecture

Deployment of Palo Alto Networks VM-Series into one of its [Reference Architectures](https://pandocs.tech/fw/110p-prime): the *Centralized* design using *Combined Inbound Security*.

In a nutshell it means:

- Multiple Application VPCs can be secured using a single Security VPC.
- The outbound traffic traverses transit gateway (TGW) and gateway load balancer (GWLB).
- The inbound traffic _does not_ traverse TGW and only traverses GWLB.
- The inbound traffic traverses a _single_ interface per each VM-Series, so it is in intrazone category instead of interzone. There is no overlay routing on VM-Series.
- The outbound traffic flows in the same manner, which is a slight departure from the Reference Architecture.
