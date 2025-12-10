# OPA Policies for Cost Control
package terraform.cost

import future.keywords.contains
import future.keywords.if

# Define allowed instance types per environment
allowed_dev_instances := ["t3.micro", "t3.small", "t3.medium", "t2.micro", "t2.small", "t2.medium"]
allowed_prod_instances := ["m6a.large", "m6a.xlarge"]

# Deny expensive instance types in dev
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_node_group"
    contains(resource.address, "dev")
    instance_type := resource.change.after.instance_types[_]
    not instance_type in allowed_dev_instances
    msg := sprintf("Dev environment '%s' cannot use expensive instance type: %s. Allowed: %v", 
        [resource.address, instance_type, allowed_dev_instances])
}

# Deny disallowed instance types in prod
# Prod will only allow the amd based instance
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_node_group"
    contains(resource.address, "prod")
    instance_type := resource.change.after.instance_types[_]
    not instance_type in allowed_prod_instances
    msg := sprintf("Prod environment '%s' instance type %s not in allowed list: %v", 
        [resource.address, instance_type, allowed_prod_instances])
}

# Limit disk size for dev environments
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_launch_template"
    contains(resource.address, "dev")
    volume := resource.change.after.block_device_mappings[_]
    volume.ebs.volume_size > 50
    msg := sprintf("Dev environment '%s' disk size exceeds 50GB limit: %dGB", 
        [resource.address, volume.ebs.volume_size])
}

# Warn about excessive node counts in dev
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_node_group"
    contains(resource.address, "dev")
    max_size := resource.change.after.scaling_config[_].max_size
    max_size > 5
    msg := sprintf("Warning: Dev environment '%s' max node count is high: %d nodes", 
        [resource.address, max_size])
}

# Ensure production uses appropriate instance sizes
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_node_group"
    contains(resource.address, "prod")
    instance_type := resource.change.after.instance_types[_]
    contains(instance_type, "micro")
    msg := sprintf("Warning: Production environment '%s' using potentially undersized instance: %s", 
        [resource.address, instance_type])
}

# Warn about NAT Gateway costs
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_nat_gateway"
    resource.change.actions[_] == "create"
    msg := sprintf("Warning: NAT Gateway '%s' incurs hourly charges and data transfer costs", [resource.address])
}

# Ensure cost tags are present
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    expensive_resources := ["aws_eks_cluster", "aws_nat_gateway", "aws_lb"]
    resource.type in expensive_resources
    not resource.change.after.tags.CostCenter
    msg := sprintf("Expensive resource '%s' must have CostCenter tag for billing", [resource.address])
}

