# Root-level outputs that delegate to the active environment module

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.environment == "dev" ? module.dev[0].vpc_id : module.prod[0].vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.environment == "dev" ? module.dev[0].vpc_cidr : module.prod[0].vpc_cidr
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = var.environment == "dev" ? module.dev[0].private_subnet_ids : module.prod[0].private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.environment == "dev" ? module.dev[0].public_subnet_ids : module.prod[0].public_subnet_ids
}

# EKS Outputs
output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = var.environment == "dev" ? module.dev[0].cluster_id : module.prod[0].cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = var.environment == "dev" ? module.dev[0].cluster_arn : module.prod[0].cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.environment == "dev" ? module.dev[0].cluster_endpoint : module.prod[0].cluster_endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = var.environment == "dev" ? module.dev[0].cluster_version : module.prod[0].cluster_version
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = var.environment == "dev" ? module.dev[0].node_group_id : module.prod[0].node_group_id
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "Map of ECR repository names to URLs"
  value       = var.environment == "dev" ? module.dev[0].ecr_repository_urls : module.prod[0].ecr_repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs"
  value       = var.environment == "dev" ? module.dev[0].ecr_repository_arns : module.prod[0].ecr_repository_arns
}

output "ecr_repository_names" {
  description = "List of created ECR repository names"
  value       = var.environment == "dev" ? module.dev[0].ecr_repository_names : module.prod[0].ecr_repository_names
}
