# OPA Security Policies for Terraform
package terraform.security

import future.keywords.contains
import future.keywords.if

# Ensure all S3 buckets are encrypted
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource.address)
    msg := sprintf("S3 bucket '%s' must have encryption enabled", [resource.address])
}

# Helper to check for encryption configuration
has_encryption(bucket_address) {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_server_side_encryption_configuration"
    contains(resource.address, bucket_address)
}

# Ensure EBS volumes are encrypted
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    resource.change.after.encrypted == false
    msg := sprintf("EBS volume '%s' must be encrypted", [resource.address])
}

# Ensure RDS instances are encrypted
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == false
    msg := sprintf("RDS instance '%s' must have storage encryption enabled", [resource.address])
}

# Ensure security groups don't allow unrestricted access to sensitive ports
sensitive_ports := [22, 3389, 3306, 5432, 1433, 6379, 27017]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    port := rule.from_port
    port in sensitive_ports
    cidr := rule.cidr_blocks[_]
    cidr == "0.0.0.0/0"
    msg := sprintf("Security group '%s' allows unrestricted access to sensitive port %d from 0.0.0.0/0", 
        [resource.address, port])
}

# Ensure IMDSv2 is required for EC2 instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_launch_template"
    metadata := resource.change.after.metadata_options[_]
    metadata.http_tokens != "required"
    msg := sprintf("Launch template '%s' must require IMDSv2 (http_tokens = required)", [resource.address])
}

# Ensure ALB has access logging enabled for production
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    contains(resource.address, "prod")
    not resource.change.after.access_logs
    msg := sprintf("Warning: Production ALB '%s' should have access logging enabled", [resource.address])
}

# Ensure CloudWatch logs are encrypted
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    not resource.change.after.kms_key_id
    msg := sprintf("Warning: CloudWatch log group '%s' is not encrypted with KMS", [resource.address])
}

# Ensure IAM roles have trust policies restricted
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_role"
    policy := json.unmarshal(resource.change.after.assume_role_policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Principal == "*"
    msg := sprintf("IAM role '%s' has overly permissive trust policy allowing '*'", [resource.address])
}

# Ensure VPC flow logs are enabled
warn[msg] {
    vpc_exists
    not flow_log_exists
    msg := "Warning: VPC flow logs should be enabled for network monitoring"
}

# Helper to check if VPC exists
vpc_exists {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.actions[_] == "create"
}

# Helper to check if flow log exists
flow_log_exists {
    resource := input.resource_changes[_]
    resource.type == "aws_flow_log"
    resource.change.actions[_] == "create"
}

# Ensure public subnets are intentional
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == true
    not contains(resource.change.after.tags.Name, "public")
    msg := sprintf("Warning: Subnet '%s' auto-assigns public IPs but isn't named as public", [resource.address])
}

# Ensure EKS cluster has audit logging enabled
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_cluster"
    not resource.change.after.enabled_cluster_log_types
    msg := sprintf("Warning: EKS cluster '%s' should have control plane logging enabled", [resource.address])
}

