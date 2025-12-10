# Prod Environment Module
# This module is called from the root main.tf when environment = "prod"

locals {
  cluster_name = "${var.project}-${var.environment}-eks"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  tags = var.tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name            = local.cluster_name
  environment             = var.environment
  kubernetes_version      = "1.34"
  subnet_ids              = module.vpc.private_subnet_ids
  endpoint_private_access = true
  endpoint_public_access  = false
  public_access_cidrs     = []
  desired_size            = var.node_desired_size
  max_size                = var.node_max_size
  min_size                = var.node_min_size
  instance_types          = ["m6a.large"]
  disk_size               = 50

  tags = var.tags

  depends_on = [module.vpc]
}

# ECR Repository
module "ecr" {
  source = "../../modules/ecr"

  project                  = var.project
  environment              = var.environment
  repository_names         = ["app", "worker"]
  image_tag_mutability     = "IMMUTABLE"
  scan_on_push             = true
  enable_deletion_protection = true

  tags = var.tags
}

