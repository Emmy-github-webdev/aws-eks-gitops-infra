resource "aws_iam_role" "my_api" {
  name = "enterprise-production-my-api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "my_api" {
  name = "enterprise-production-my-api"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          "${aws_s3_bucket.application.arn}/my-api/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "my_api" {
  role       = aws_iam_role.my_api.name
  policy_arn = aws_iam_policy.my_api.arn
}

resource "aws_eks_pod_identity_association" "my_api" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "production"
  service_account = "my-api"

  role_arn = aws_iam_role.my_api.arn
}