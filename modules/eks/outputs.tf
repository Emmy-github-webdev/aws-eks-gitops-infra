output "cluster_name" {
  value = aws_eks_cluster.e_g_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.e_g_cluster.endpoint
}

output "cluster_security_group_id" {
  value = aws_security_group.e_g_cluster.id
}

output "node_security_group_id" {
  value = aws_security_group.nodes.id
}

output "node_role_arn" {
  value = aws_iam_role.nodes.arn
}

output "cluster_certificate_authority" {
  value     = aws_eks_cluster.e_g_cluster.certificate_authority[0].data
  sensitive = true
}