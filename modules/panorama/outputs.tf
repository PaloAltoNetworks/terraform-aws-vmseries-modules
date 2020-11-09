output "panoramas" {
  value = {
    for k, panorama in aws_instance.this :
    k => {
      # name = bucket.id
      id         = panorama.id
      public_ip  = panorama.public_ip
      private_ip = panorama.private_ip
      key_name   = panorama.key_name
    }
  }
}