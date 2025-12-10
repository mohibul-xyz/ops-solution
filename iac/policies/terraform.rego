# OPA Policies for Terraform Infrastructure
package terraform

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Resources that do NOT support tags in AWS
non_taggable_resources := [
    "aws_iam_role",
    "aws_iam_role_policy",
    "aws_iam_role_policy_attachment",
    "aws_iam_policy",
    "aws_iam_policy_attachment",
    "aws_route",
    "aws_route_table_association",
    "aws_ecr_lifecycle_policy",
    "aws_ecr_repository_policy",
    "aws_ecr_registry_policy",
    "aws_ecr_registry_scanning_configuration",
    "aws_vpc_dhcp_options_association",
    "aws_vpc_ipv4_cidr_block_association"
]

# Helper to check if resource supports tags
supports_tags(resource_type) {
    not resource_type in non_taggable_resources
}

# Deny resources without required tags (only for resources that support tags)
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    supports_tags(resource.type)
    not resource.change.after.tags.Environment
    msg := sprintf("Resource '%s' is missing required tag: Environment", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    supports_tags(resource.type)
    not resource.change.after.tags.ManagedBy
    msg := sprintf("Resource '%s' is missing required tag: ManagedBy", [resource.address])
}

# Ensure VPC has DNS support enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.after.enable_dns_support == false
    msg := sprintf("VPC '%s' must have DNS support enabled", [resource.address])
}

# Ensure VPC has DNS hostnames enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.after.enable_dns_hostnames == false
    msg := sprintf("VPC '%s' must have DNS hostnames enabled", [resource.address])
}

# Ensure EKS clusters have private endpoint access enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_cluster"
    resource.change.after.vpc_config[_].endpoint_private_access == false
    msg := sprintf("EKS cluster '%s' must have private endpoint access enabled", [resource.address])
}

# Ensure EKS node groups use encrypted volumes
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_launch_template"
    contains(resource.address, "eks")
    block := resource.change.after.block_device_mappings[_]
    block.ebs.encrypted == false
    msg := sprintf("Launch template '%s' must use encrypted EBS volumes", [resource.address])
}

# Ensure security groups don't allow unrestricted SSH access
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.from_port == 22
    rule.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' allows unrestricted SSH access from 0.0.0.0/0", [resource.address])
}

# Ensure ALB has deletion protection in production
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    contains(resource.address, "prod")
    resource.change.after.enable_deletion_protection == false
    msg := sprintf("Production ALB '%s' must have deletion protection enabled", [resource.address])
}

# Ensure CloudWatch log groups have retention policies
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    not resource.change.after.retention_in_days
    msg := sprintf("CloudWatch log group '%s' must have a retention policy", [resource.address])
}

# Ensure NAT Gateway is enabled for private subnets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    contains(resource.change.after.tags.Name, "private")
    not has_nat_gateway
    msg := sprintf("Private subnet '%s' requires NAT Gateway for internet access", [resource.address])
}

# Helper function to check if NAT gateway exists
has_nat_gateway {
    resource := input.resource_changes[_]
    resource.type == "aws_nat_gateway"
    resource.change.actions[_] == "create"
}

# Ensure API Gateway has CloudWatch logging enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_apigatewayv2_stage"
    not resource.change.after.access_log_settings
    msg := sprintf("API Gateway stage '%s' must have CloudWatch logging enabled", [resource.address])
}

# Warn about public EKS endpoints in production
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_cluster"
    contains(resource.address, "prod")
    resource.change.after.vpc_config[_].endpoint_public_access == true
    msg := sprintf("Warning: Production EKS cluster '%s' has public endpoint access enabled", [resource.address])
}

# Ensure proper naming convention
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    resource.change.after.tags.Name
    name := resource.change.after.tags.Name
    not contains(name, "-")
    msg := sprintf("Resource '%s' name '%s' should follow kebab-case naming convention", [resource.address, name])
}

# Count violations for reporting
violation_count := count(deny)
warning_count := count(warn)

