# Create SSH key pair for Panorama instance
resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.name_prefix}${random_string.random_sufix.id}"
  public_key = tls_private_key.generated_key.public_key_openssh
}
