
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    3
  )

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 0),
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2)
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 1),
    cidrsubnet(var.vpc_cidr, 4, 2),
    cidrsubnet(var.vpc_cidr, 4, 3)
  ]

  database_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 100),
    cidrsubnet(var.vpc_cidr, 8, 101),
    cidrsubnet(var.vpc_cidr, 8, 102)
  ]

  intra_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 110),
    cidrsubnet(var.vpc_cidr, 8, 111),
    cidrsubnet(var.vpc_cidr, 8, 112)
  ]

  public_subnet_map = {
    for index, az in local.azs :
    az => local.public_subnets[index]
  }

  private_subnet_map = {
    for index, az in local.azs :
    az => local.private_subnets[index]
  }

  database_subnet_map = {
    for index, az in local.azs :
    az => local.database_subnets[index]
  }

  intra_subnet_map = {
    for index, az in local.azs :
    az => local.intra_subnets[index]
  }

  nat_gateway_count = var.single_nat_gateway ? 1 : length(local.azs)

  common_tags = merge(var.tags, {
    Name = var.name
  })
}
