region = "us-east-1"

global_tags = {
  Environment = "us-east-1"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

panoramas = {
  panorama01 = {
    name             = "panorama01"
    local_tags       = { "foo" = "bar" }
    ssh_key_name     = "bar"
    instance_type    = "m5.2xlarge"
    panorama_version = "9.1.2"
    security_groups  = "foo"
    subnet_id        = "bar"
    private_ip       = "10.100.100.100"
    public_ip        = true
    ebs = {
      device_name       = "/dev/sdb"
      size              = 2000
      availability_zone = "us-east-1a"
    }
  }
}
