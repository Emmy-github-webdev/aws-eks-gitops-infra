
resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  })

  depends_on = [
    aws_internet_gateway.e_g_igw
  ]
}

resource "aws_nat_gateway" "e_g_nat" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id

  subnet_id = aws_subnet.public[
    local.azs[var.single_nat_gateway ? 0 : count.index]
  ].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${count.index + 1}"
  })

  depends_on = [
    aws_internet_gateway.e_g_igw
  ]
}
