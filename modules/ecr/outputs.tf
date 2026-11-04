output "repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.e_g_ecr :
    name => repo.repository_url
  }
}