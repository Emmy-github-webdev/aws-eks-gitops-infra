
resource "aws_vpc" "e_g_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "e_g_igw" {
  vpc_id = aws_vpc.e_g_vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}
