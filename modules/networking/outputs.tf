
output "vpc_id" {
  value = aws_vpc.e_g_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.e_g_vpc.cidr_block
}

output "availability_zones" {
  value = local.azs
}

output "public_subnets" {
  value = [
    for subnet in aws_subnet.public_subnet : subnet.id
  ]
}

output "private_subnets" {
  value = [
    for subnet in aws_subnet.private_subnet : subnet.id
  ]
}

output "database_subnets" {
  value = [
    for subnet in aws_subnet.database_subnet : subnet.id
  ]
}

output "intra_subnets" {
  value = [
    for subnet in aws_subnet.intra_subnet : subnet.id
  ]
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.e_g_nat[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.e_g_igw.id
}

output "admin_security_group_id" {
  value = aws_security_group.sg.id
}
