variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "aurora_engine_version" {
  type = string
}

variable "admin_instance_type" {
  type    = string
  default = "t3.small"
}

variable "node_instance_type" {
  type    = string
  default = "m7i.large"
}