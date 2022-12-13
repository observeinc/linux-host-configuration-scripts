resource "aws_security_group" "ec2_public" {
  name   = format(var.name_format, "ec2_sg")
  vpc_id = data.aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    var.BASE_TAGS,
    {
      Name = format(var.name_format, "_ec2")
    },
  )
}
