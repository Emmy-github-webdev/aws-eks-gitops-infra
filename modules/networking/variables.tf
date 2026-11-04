
variable "name" {
  description = "Name prefix for networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR block"
  type        = string
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "log_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Flow Logs"
  type        = string
  default  = null
  nullable = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
