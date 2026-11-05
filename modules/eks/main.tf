data "aws_partition" "current" {}

# -----------------------------
# EKS cluster IAM
# -----------------------------

resource "aws_iam_role" "cluster" {
  name = "${var.name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy" "cluster_kms" {
  name = "${var.name}-kms"
  role = aws_iam_role.cluster.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:DescribeKey",
        "kms:CreateGrant"
      ]
      Resource = var.eks_kms_key_arn
    }]
  })
}

# -----------------------------
# Security groups
# -----------------------------

resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "EKS control plane security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "nodes" {
  name        = "${var.name}-nodes"
  description = "EKS worker node security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Control plane to kubelet and node services"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    description     = "Control plane HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    description = "Node-to-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "admin_api" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = var.admin_security_group_id

  description = "Administrative host access to private EKS API"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "node_api" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id

  description = "Worker nodes access to EKS API"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# -----------------------------
# EKS cluster
# -----------------------------

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = 90
}

resource "aws_eks_cluster" "e_g_cluster" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn

  version = var.kubernetes_version

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids = var.private_subnet_ids

    endpoint_private_access = true
    endpoint_public_access  = false

    security_group_ids = [
      aws_security_group.cluster.id
    ]
  }

  encryption_config {
    provider {
      key_arn = var.eks_kms_key_arn
    }

    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy.cluster_kms,
    aws_cloudwatch_log_group.eks
  ]

  tags = var.tags
}

# -----------------------------
# Worker node IAM
# -----------------------------

resource "aws_iam_role" "nodes" {
  name = "${var.name}-node-role"

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
}

locals {
  node_policies = [
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset(local.node_policies)

  role       = aws_iam_role.nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.value}"
}

# -----------------------------
# Encrypted launch template
# -----------------------------

resource "aws_launch_template" "nodes" {
  name_prefix   = "${var.name}-nodes-"
  description   = "Hardened EKS worker launch template"
  update_default_version = true

  vpc_security_group_ids = [
    aws_security_group.nodes.id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = var.tags
  }

  tag_specifications {
    resource_type = "volume"

    tags = var.tags
  }
}

# -----------------------------
# Managed node group
# -----------------------------

resource "aws_eks_node_group" "e_g_node_group" {
  cluster_name    = aws_eks_cluster.e_g_cluster.name
  node_group_name = "${var.name}-general"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.private_subnet_ids

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = tostring(aws_launch_template.nodes.latest_version)
  }

  labels = {
    workload = "general"
  }

  depends_on = [
    aws_eks_cluster.e_g_cluster,
    aws_iam_role_policy_attachment.nodes
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}

# -----------------------------
# Administrative access entry
# -----------------------------

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.e_g_cluster.name
  principal_arn = var.admin_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.e_g_cluster.name
  principal_arn = var.admin_role_arn

  policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.admin
  ]
}

# -----------------------------
# EKS managed add-ons
# -----------------------------

locals {
  addon_names = [
    "vpc-cni",
    "coredns",
    "kube-proxy",
    "eks-pod-identity-agent"
  ]
}

data "aws_eks_addon_version" "e_g_addon_version" {
  for_each = toset(local.addon_names)

  addon_name         = each.value
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

resource "aws_eks_addon" "e_g_addon" {
  for_each = toset(local.addon_names)

  cluster_name = aws_eks_cluster.e_g_cluster.name
  addon_name   = each.value
  addon_version = data.aws_eks_addon_version.e_g_addon_version[each.value].version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.e_g_node_group
  ]

  tags = var.tags
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main.name

  addon_name    = "eks-pod-identity-agent"
  addon_version = var.pod_identity_agent_version
}