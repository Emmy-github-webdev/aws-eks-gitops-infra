module "kms_ecr" {
  source = "../../modules/kms"

  description = "Shared ECR encryption"
  alias_name  = "shared/ecr"
}

module "ecr" {
  source = "../../modules/ecr"

  repositories = [
    "my-api",
    "my-frontend",
    "my-worker"
  ]

  kms_key_arn = module.kms_ecr.key_arn

  tags = {
    ManagedBy = "Terraform"
    Project   = "enterprise-platform"
    Scope     = "shared"
  }
}