resource "aws_db_subnet_group" "db_sg" {
  name       = "${var.name}-subnets"
  subnet_ids = var.database_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "Aurora access from EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = var.node_security_group_id

  description = "PostgreSQL from EKS worker nodes"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
}

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = var.name

  engine         = "aurora-postgresql"
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = "dbadmin"

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.rds_db_sg.name
  vpc_security_group_ids = [aws_security_group.database.id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  iam_database_authentication_enabled = true

  backup_retention_period = var.backup_retention_days
  preferred_backup_window = "02:00-03:00"

  preferred_maintenance_window = "sun:04:00-sun:05:00"

  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]

  deletion_protection = var.deletion_protection

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final"

  copy_tags_to_snapshot = true

  apply_immediately = false

  tags = var.tags
}

resource "aws_rds_cluster_instance" "rds_instance" {
  count = var.instance_count

  identifier = "${var.name}-${count.index + 1}"

  cluster_identifier = aws_rds_cluster.rds_cluster.id

  engine         = aws_rds_cluster.rds_cluster.engine
  engine_version = aws_rds_cluster.rds_cluster.engine_version

  instance_class = var.instance_class

  publicly_accessible = false

  auto_minor_version_upgrade = true

  performance_insights_enabled = true

  tags = var.tags
}
