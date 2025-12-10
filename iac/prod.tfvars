# Production Environment Configuration

project     = "practice-project"
environment = "prod"

# VPC Configuration
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
public_subnets     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnets    = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
enable_nat_gateway = true

# EKS Node Group Configuration
node_desired_size = 3
node_min_size     = 3
node_max_size     = 10

# Tags
tags = {
  Environment = "prod"
  Owner       = "DevOps"
  Terraform   = "true"
  CostCenter  = "engineering"
  Compliance  = "required"
}
