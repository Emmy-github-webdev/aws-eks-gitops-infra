variable "name" {
  type = string
}

variable "database_name" {
  type    = string
  default = "application"
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "backup_retention_days" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

variable "vpc_id" {
  type = string
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}