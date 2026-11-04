
resource "aws_subnet" "public_subnet" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.e_g_vpc.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${var.name}-public-${each.key}"
    NetworkTier              = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private_subnet" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.e_g_vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(local.common_tags, {
    Name                              = "${var.name}-private-${each.key}"
    NetworkTier                       = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "database_subnet" {
  for_each = local.database_subnet_map

  vpc_id            = aws_vpc.e_g_vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(local.common_tags, {
    Name        = "${var.name}-database-${each.key}"
    NetworkTier = "database"
  })
}

resource "aws_subnet" "intra_subnet" {
  for_each = local.intra_subnet_map

  vpc_id            = aws_vpc.e_g_vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(local.common_tags, {
    Name        = "${var.name}-intra-${each.key}"
    NetworkTier = "infrastructure"
  })
}
