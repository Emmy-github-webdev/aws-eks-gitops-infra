
resource "aws_security_group" "sg" {
  name        = "${var.name}-admin"
  description = "SSM administration host"
  vpc_id      = aws_vpc.e_g_vpc.id

  egress {
    description = "Outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-sg"
  })
}
