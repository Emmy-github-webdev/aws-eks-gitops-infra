aws_region  = "us-east-1"
environment = "staging"

vpc_cidr     = "10.10.0.0/16"
cluster_name = "enterprise-staging"


kubernetes_version     = "REPLACE_WITH_SUPPORTED_EKS_VERSION"
aurora_engine_version  = "REPLACE_WITH_SUPPORTED_AURORA_VERSION"

admin_instance_type = "t3.small"
node_instance_type  = "m7i.large"