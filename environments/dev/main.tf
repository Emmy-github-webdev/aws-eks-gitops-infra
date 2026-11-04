data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  production = var.environment == "production"

  common_tags = {
    Environment = var.environment
    Project     = "enterprise-eks"
    ManagedBy   = "Terraform"
  }

  single_nat = !local.production

  node_min     = local.production ? 3 : 2
  node_desired = local.production ? 3 : 2
  node_max     = local.production ? 9 : 4

  database_instances = local.production ? 2 : 1
  database_class     = local.production ? "db.r7g.large" : "db.t4g.medium"

  backup_days = local.production ? 35 : 7
}

# -----------------------------
# KMS keys
# -----------------------------

module "kms_eks" {
  source = "../../modules/kms"

  description = "${var.environment} EKS secrets encryption"
  alias_name  = "${var.environment}/eks"

  tags = local.common_tags
}

module "kms_ebs" {
  source = "../../modules/kms"

  description = "${var.environment} EBS encryption"
  alias_name  = "${var.environment}/ebs"

  tags = local.common_tags
}

module "kms_rds" {
  source = "../../modules/kms"

  description = "${var.environment} Aurora encryption"
  alias_name  = "${var.environment}/rds"

  tags = local.common_tags
}

# -----------------------------
# Networking
# -----------------------------

module "networking" {
  source = "../../modules/networking"

  name    = "${var.environment}-platform"
  vpc_cidr = var.vpc_cidr

  single_nat_gateway = local.single_nat


  log_kms_key_arn = null

  tags = local.common_tags
}

# -----------------------------
# Administrative host IAM
# -----------------------------

resource "aws_iam_role" "admin_host" {
  name = "${var.environment}-eks-admin-host"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "admin_ssm" {
  role = aws_iam_role.admin_host.name

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "admin_eks" {
  name = "${var.environment}-eks-admin-describe"
  role = aws_iam_role.admin_host.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster"
      ]
      Resource = "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
    }]
  })
}

resource "aws_iam_instance_profile" "admin_host" {
  name = "${var.environment}-eks-admin-host"
  role = aws_iam_role.admin_host.name
}

# -----------------------------
# EKS
# -----------------------------

module "eks" {
  source = "../../modules/eks"

  name = var.cluster_name

  vpc_id = module.networking.vpc_id

  private_subnet_ids = module.networking.private_subnets

  admin_security_group_id = module.networking.admin_security_group_id
  admin_role_arn          = aws_iam_role.admin_host.arn

  eks_kms_key_arn = module.kms_eks.key_arn
  ebs_kms_key_arn = module.kms_ebs.key_arn

  kubernetes_version = var.kubernetes_version

  node_instance_type = var.node_instance_type

  node_disk_size   = 50
  node_min_size    = local.node_min
  node_desired_size = local.node_desired
  node_max_size    = local.node_max

  tags = local.common_tags
}

# -----------------------------
# SSM administration instance
# -----------------------------

resource "aws_instance" "admin_host" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.admin_instance_type
  subnet_id              = module.networking.private_subnets[0]
  vpc_security_group_ids = [module.networking.admin_security_group_id]

  iam_instance_profile = aws_iam_instance_profile.admin_host.name

  associate_public_ip_address = false

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    dnf install -y curl

    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

    curl -fsSL \
      -o /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

    chmod +x /usr/local/bin/kubectl
  EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = module.kms_ebs.key_arn
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.admin_ssm
  ]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-eks-admin"
  })
}

# -----------------------------
# Aurora PostgreSQL
# -----------------------------

module "aurora" {
  source = "../../modules/aurora"

  name = "${var.environment}-aurora"

  database_name = "application"

  engine_version = var.aurora_engine_version

  instance_class = local.database_class
  instance_count = local.database_instances

  backup_retention_days = local.backup_days
  deletion_protection   = local.production

  vpc_id = module.networking.vpc_id

  database_subnet_ids = module.networking.database_subnets

  node_security_group_id = module.eks.node_security_group_id

  kms_key_arn = module.kms_rds.key_arn

  tags = local.common_tags
}