output "cluster_endpoint" {
  value = aws_rds_cluster.rds_cluster.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.rds_cluster.reader_endpoint
}

output "port" {
  value = aws_rds_cluster.rds_cluster.port
}

output "database_name" {
  value = aws_rds_cluster.rds_cluster.database_name
}

output "master_secret_arn" {
  value     = aws_rds_cluster.rds_cluster.master_user_secret[0].secret_arn
  sensitive = true
}

output "security_group_id" {
  value = aws_security_group.database.id
}