# ECR Module Outputs

output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.arn
  }
}

output "repository_ids" {
  description = "Map of repository names to their registry IDs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.registry_id
  }
}

output "repository_names" {
  description = "List of created repository names"
  value       = [for repo in aws_ecr_repository.main : repo.name]
}

