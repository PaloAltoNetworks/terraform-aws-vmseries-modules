# VM-Series in the Centralized Design Combined Inbound Architecture

Deployment of Palo Alto Networks VM-Series into one of its reference architectures: the *Centralized* design using *Combined Inbound Security*.

In a nutshell it means:

- multiple Application VPCs can be secured using a single Security VPC
- the inbound traffic _does not_ require source network address translation (no SNAT)
- creates transit gateway (TGW) and gateway load balancers (GWLBs)
