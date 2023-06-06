vmseries = {
  vmseries01 = {
    az = "us-east-1a"
    interfaces = {
      data1 = {
        device_index      = 0
        security_group    = "vmseries_data1"
        source_dest_check = false
        subnet            = "data1"
        create_public_ip  = false
      },
      mgmt = {
        device_index      = 1
        security_group    = "vmseries_mgmt"
        source_dest_check = true
        subnet            = "mgmt"
        create_public_ip  = true
      }
    }
  }
}