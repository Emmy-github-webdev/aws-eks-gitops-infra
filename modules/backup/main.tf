resource "aws_backup_vault" "eks" {
  name        = "enterprise-eks-backup"
  kms_key_arn = var.backup_kms_key_arn
}

resource "aws_backup_vault" "rds" {
  name        = "enterprise-rds-backup"
  kms_key_arn = var.backup_kms_key_arn
}

resource "aws_backup_plan" "eks" {
  name = "enterprise-eks-daily"

  rule {
    rule_name         = "daily-eks-backup"
    target_vault_name = aws_backup_vault.eks.name

    schedule = "cron(0 2 * * ? *)"

    lifecycle {
      delete_after = 35
    }
  }
}