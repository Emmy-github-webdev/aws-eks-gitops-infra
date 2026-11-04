output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "admin_instance_id" {
  value = aws_instance.admin_host.id
}

output "aurora_endpoint" {
  value = module.aurora.cluster_endpoint
}

output "aurora_reader_endpoint" {
  value = module.aurora.reader_endpoint
}

output "aurora_secret_arn" {
  value     = module.aurora.master_secret_arn
  sensitive = true
}