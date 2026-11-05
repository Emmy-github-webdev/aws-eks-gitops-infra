variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "admin_security_group_id" {
  type = string
}

variable "admin_role_arn" {
  type = string
}

variable "eks_kms_key_arn" {
  type = string
}

variable "ebs_kms_key_arn" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "node_instance_type" {
  type = string
}

variable "node_disk_size" {
  type    = number
  default = 50
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_desired_size" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "pod_identity_agent_version" {
  description = "Version of the EKS Pod Identity Agent addon"
  type        = string
}