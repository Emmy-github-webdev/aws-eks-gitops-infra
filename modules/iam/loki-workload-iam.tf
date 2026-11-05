resource "aws_iam_role" "loki_iam_role" {
  name = "enterprise-production-loki-iam-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource": [
          "arn:aws:s3:::YOUR_LOKI_BUCKET",
          "arn:aws:s3:::YOUR_LOKI_BUCKET/*"
        ]
      }
    ]
  })
}