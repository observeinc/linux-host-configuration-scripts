/* Locally generated private key*/
# RSA key of size 4096 bits
resource "tls_private_key" "rsa_ec2key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "ec2key" {
  key_name   = format(var.name_format, "publicKey")
  public_key = tls_private_key.rsa_ec2key.public_key_openssh

  tags = merge(
    var.BASE_TAGS,
    {
      Name = format(var.name_format, "_publicKey")
    },
  )
}

resource "local_file" "rsa_ec2key" {
  content         = tls_private_key.rsa_ec2key.private_key_pem
  filename        = "${path.module}/keys/ephemeral_key"
  file_permission = "400"
}
