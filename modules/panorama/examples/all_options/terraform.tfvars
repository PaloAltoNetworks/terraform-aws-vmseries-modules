region = "us-east-1"

global_tags = {
  Environment = "us-east-1"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

panoramas = {
  panorama01 = {
    name              = "panorama01"
    local_tags        = { "foo" = "bar" }
    ssh_key_name      = "bar"
    instance_type     = "m5.2xlarge"
    security_groups   = "sg1"
    subnet_id         = "mgmt"
    private_ip        = "10.0.0.100"
    public_ip         = true
    availability_zone = "us-east-1f"
    ebs = {
      device_name = "/dev/sdb"
      size        = 2000
    }
  }
}
