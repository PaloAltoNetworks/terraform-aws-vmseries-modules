region = "us-east-1"

prefix_name_tag = "panorama-module-" // Used for resource name Tags. Leave as empty string if not desired

global_tags = {
  Environment = "us-east-1"
  Managed_By  = "Terraform"
  Description = "Demo of all resource types and optional parameters supported by this module"
}

panoramas = {
  panorama01 = {
    name             = "panorama01"
    local_tags       = { "foo" = "bar" }
    ssh_key_name     = "foo"
    instance_type    = "m5.2xlarge"
    panorama_version = "9.1.2"
    security_groups  = "foo"
    subnet_id        = "bar"
    private_ip       = "10.1.1.1"
    public_ip        = true
    ebs = {
      device_name       = "/dev/sdb"
      size              = 2000
      availability_zone = "us-east-1a"
    }
  }
}
