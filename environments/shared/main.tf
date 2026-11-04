data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "audit" {
  bucket = "REPLACE_WITH_UNIQUE_AUDIT_BUCKET_NAME"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Purpose = "security-audit"
  }
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit" {
  bucket = aws_s3_bucket.audit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "account" {
  name                          = "enterprise-account-trail"
  s3_bucket_name                = aws_s3_bucket.audit.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  depends_on = [
    aws_s3_bucket_policy.audit
  ]

  tags = {
    Purpose = "account-audit"
  }
}

resource "aws_s3_bucket_policy" "audit" {
  bucket = aws_s3_bucket.audit.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit.arn

        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/enterprise-account-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:PutObject"

        Resource = "${aws_s3_bucket.audit.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

        Condition = {
          StringEquals = {
            "s3:x-amz-acl"       = "bucket-owner-full-control"
            "aws:SourceArn"      = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/enterprise-account-trail"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          aws_s3_bucket.audit.arn,
          "${aws_s3_bucket.audit.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}


resource "aws_guardduty_detector" "main" {
  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_securityhub_account" "main" {
  enable_default_standards = true

  depends_on = [
    aws_guardduty_detector.main
  ]
}

resource "aws_iam_policy" "ecr_push" {
  name        = "enterprise-ecr-push"
  description = "Allow CI/CD to publish container images"

  policy = templatefile(
    "${path.module}/policies/ecr-push-policy.json",
    {
      aws_region = var.aws_region
      account_id = data.aws_caller_identity.current.account_id
    }
  )

  tags = {
    ManagedBy = "Terraform"
    Scope     = "shared"
  }
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.ci_cd.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

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