output "aws_key_pair_name" {
  value = aws_key_pair.ec2key.key_name
}

output "aws_key_path" {
  value = local_file.rsa_ec2key.filename != null ? local_file.rsa_ec2key.filename : "NO_PATH"
}
