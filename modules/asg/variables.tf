variable "vmseries_version" {
  description = "Select which FW version to deploy"
  default     = "10.2.2"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "fw_license_type" {
  description = "Select License type (byol/payg1/payg2)"
  default     = "byol"
}

variable "vmseries_product_code" {
  description = <<-EOF
  Product code corresponding to a chosen VM-Series license type model - by default - BYOL.
  To check the available license type models and their codes, please refer to the
  [VM-Series documentation](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/obtain-the-ami/get-amazon-machine-image-ids.html)
  EOF
  default     = "6njl1pau431dv1qxipg63mvah"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  default     = "m5.xlarge"
  type        = string
}

variable "vmseries_ami_id" {
  description = "The AMI from which to launch the instance. Takes precedence over fw_version and fw_license_type"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "All resource names will be prepended with this string"
  type        = string
}

variable "asg_name" {
  description = "Name of the autoscaling group to create"
  type        = string
  default     = "asg"
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances"
  type        = string
}

variable "launch_template_update_default_version" {
  description = <<EOF
  Whether to update launch template default version each update.

  If set to true, every time when e.g. bootstrap options are changed, new version is created and default version is updated.
  If set to false, every time when e.g. bootstrap options are changed, new version is created, but default version is not changed.
  EOF
  type        = bool
  default     = true
}

variable "bootstrap_options" {
  description = "Bootstrap options to put into userdata"
  type        = any
  default     = {}
}

variable "interfaces" {
  description = <<-EOF
  Map of the network interface specifications.
  If "mgmt-interface-swap" bootstrap option is enabled, ensure dataplane interface `device_index` is set to 0 and the firewall management interface `device_index` is set to 1.
  Available options:
  - `device_index`       = (Required|int) Determines order in which interfaces are attached to the instance. Interface with `0` is attached at boot time.
  - `subnet_id`          = (Required|string) Subnet ID to create the ENI in.
  - `name`               = (Optional|string) Name tag for the ENI. Defaults to instance name suffixed by map's key.
  - `description`        = (Optional|string) A descriptive name for the ENI.
  - `create_public_ip`   = (Optional|bool) Whether to create a public IP for the ENI. Defaults to false.
  - `eip_allocation_id`  = (Optional|string) Associate an existing EIP to the ENI.
  - `private_ips`        = (Optional|list) List of private IPs to assign to the ENI. If not set, dynamic allocation is used.
  - `public_ipv4_pool`   = (Optional|string) EC2 IPv4 address pool identifier.
  - `source_dest_check`  = (Optional|bool) Whether to enable source destination checking for the ENI. Defaults to false.
  - `security_group_ids` = (Optional|list) A list of Security Group IDs to assign to this interface. Defaults to null.

  Example:
  ```
  interfaces = {
    mgmt = {
      device_index       = 0
      subnet_id          = aws_subnet.mgmt.id
      name               = "mgmt"
      create_public_ip   = true
      source_dest_check  = true
      security_group_ids = ["sg-123456"]
    },
    public = {
      device_index     = 1
      subnet_id        = aws_subnet.public.id
      name             = "public"
      create_public_ip = true
    },
    private = {
      device_index = 2
      subnet_id    = aws_subnet.private.id
      name         = "private"
    },
  ]
  ```
  EOF
  # For now it's not possible to have a more strict definition of variable type, optional
  # object attributes are still experimental
  type = map(any)
}

variable "target_group_arn" {
  description = "ARN of target group (type instance) for load balancer, which is used by ASG to register VM-Series instance"
  type        = string
  default     = null
}

variable "ip_target_groups" {
  description = "Target groups (type IP) for load balancers, which are used by Lamda to register VM-Series IP of untrust interface"
  type = list(object({
    arn  = string
    port = string
  }))
  default = []
}

variable "lifecycle_hook_timeout" {
  description = "How long should we wait for lambda to finish"
  type        = number
  default     = 300
}

variable "desired_capacity" {
  description = "Number of Amazon EC2 instances that should be running in the group."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "delete_timeout" {
  description = <<EOF
  Timeout needed to correctly drain autoscaling group while deleting ASG.

  By default in AWS timeout is set to 10 minutes, which is too low and causes issue:
  Error: waiting for Auto Scaling Group (example-asg) drain: timeout while waiting for state to become '0' (last state: '1', timeout: 10m0s)
  EOF
  type        = string
  default     = "20m"
}

variable "suspended_processes" {
  description = "List of processes to suspend for the Auto Scaling Group. The allowed values are Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer, InstanceRefresh"
  type        = list(string)
  default     = []
}

variable "global_tags" {
  description = "Map of AWS tags to apply to all the created resources."
  type        = map(any)
}

variable "lambda_timeout" {
  description = "Amount of time Lambda Function has to run in seconds."
  type        = number
  default     = 30
}

variable "lambda_execute_pip_install_once" {
  description = <<EOF
  Flag used in local-exec command installing Python packages required by Lambda.

  If set to true, local-exec is executed only once, when all resources are created.
  If you need to have idempotent behaviour for terraform apply every time and you have downloaded
  all required Python packages, set it to true.

  If set to false, every time it's checked if files for package pan_os_python are downloaded.
  If not, it causes execution of local-exec command in two consecutive calls of terraform apply:
  - first time value of installed-pan-os-python is changed from true (or empty) to false
  - second time value of installed-pan-os-python is changed from false to true
  In summary while executing code from scratch, two consecutive calls of terraform apply are not idempotent.
  The third execution of terraform apply show no changes.
  While using modules in CI/CD pipelines, when agents are selected randomly, set this value to false
  in order to check every time, if pan_os_python package is downloaded. sdfdsf sdfvars
  EOF
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent execussions for lambda function."
  default     = 100
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function"
  type        = list(string)
  default     = []
}

variable "vmseries_iam_instance_profile" {
  description = "IAM instance profile used in launch template"
  type        = string
  default     = ""
}

variable "ebs_kms_id" {
  description = "Alias for AWS KMS used for EBS encryption in VM-Series"
  type        = string
  default     = "alias/aws/ebs"
}

variable "delicense_ssm_param_name" {
  description = <<-EOF
  Secure string in Parameter Store with value in below format:
  ```
  {"username":"ACCOUNT","password":"PASSWORD","panorama1":"IP_ADDRESS1","panorama2":"IP_ADDRESS2","license_manager":"LICENSE_MANAGER_NAME"}"
  ```
  EOF
  default     = null
}

variable "delicense_enabled" {
  description = "If true, then Lambda is going to delicense FW before destroying VM-Series"
  default     = false
  type        = bool
}

variable "scaling_plan_enabled" {
  description = "True, if automatic dynamic scaling policy should be created"
  type        = bool
  default     = false
}

variable "scaling_metric_name" {
  description = "Name of the metric used in dynamic scaling policy"
  type        = string
  default     = ""
}

variable "scaling_tags" {
  description = "Tags configured for dynamic scaling policy"
  type        = map(any)
  default     = {}
}

variable "scaling_target_value" {
  description = "Target value for the metric used in dynamic scaling policy"
  type        = number
  default     = 70
}

variable "scaling_statistic" {
  description = "Statistic of the metric. Valid values: Average, Maximum, Minimum, SampleCount, Sum"
  default     = "Average"
  type        = string
}

variable "scaling_cloudwatch_namespace" {
  description = "Name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)"
  type        = string
  default     = "VMseries_dimensions"
}