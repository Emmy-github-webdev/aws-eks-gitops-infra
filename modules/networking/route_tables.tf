
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.e_g_vpc.id

  tags = merge(local.common_tags, {
    Name        = "${var.name}-public-rt"
    NetworkTier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.e_g_igw.id
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table" "private_rt" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.e_g_vpc.id

  tags = merge(local.common_tags, {
    Name        = "${var.name}-private-${each.key}-rt"
    NetworkTier = "private"
  })
}

resource "aws_route" "private_nat" {
  for_each = aws_route_table.private_rt

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.e_g_nat[
    var.single_nat_gateway ? 0 : index(local.azs, each.key)
  ].id
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each = aws_subnet.private

  subnet_id = each.value.id

  route_table_id = aws_route_table.private_rt[
    each.key
  ].id
}


resource "aws_route_table" "database_rt" {
  for_each = aws_subnet.database

  vpc_id = aws_vpc.e_g_vpc.id

  tags = merge(local.common_tags, {
    Name        = "${var.name}-database-${each.key}-rt"
    NetworkTier = "database"
  })
}

resource "aws_route" "database_nat" {
  for_each = aws_route_table.database_rt

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.e_g_nat[
    var.single_nat_gateway ? 0 : index(local.azs, each.key)
  ].id
}

resource "aws_route_table_association" "database_rt_assoc" {
  for_each = aws_subnet.database

  subnet_id = each.value.id

  route_table_id = aws_route_table.database_rt[
    each.key
  ].id
}


resource "aws_route_table" "intra_rt" {
  for_each = aws_subnet.intra

  vpc_id = aws_vpc.e_g_vpc.id

  tags = merge(local.common_tags, {
    Name        = "${var.name}-intra-${each.key}-rt"
    NetworkTier = "infrastructure"
  })
}

resource "aws_route_table_association" "intra_rt_assoc" {
  for_each = aws_subnet.intra

  subnet_id = each.value.id

  route_table_id = aws_route_table.intra_rt[
    each.key
  ].id
}
