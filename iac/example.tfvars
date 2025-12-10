# Example Terraform Variables File
# Copy this file and customize the values for your environment

project     = "my-project"
environment = "dev"  # dev or prod

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.10.0/24", "10.0.20.0/24"]
enable_nat_gateway = true

# EKS Node Group Configuration
node_desired_size = 2
node_min_size     = 1
node_max_size     = 4

# Tags
tags = {
  Environment = "dev"
  Owner       = "DevOps"
  Terraform   = "true"
}
