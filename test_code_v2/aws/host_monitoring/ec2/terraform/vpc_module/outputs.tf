output "vpc_id" {
  value = aws_vpc.vpc_public.id
}

output "subnet_public_id" {
  value = aws_subnet.subnet_public.id
}

output "aws_security_group_public_id" {
  value = aws_security_group.ec2_public.id
}
