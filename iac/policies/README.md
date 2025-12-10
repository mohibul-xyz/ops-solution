# OPA Policies for Terraform

This directory contains Open Policy Agent (OPA) policies written in Rego to validate Terraform configurations.

## Policy Files

### terraform.rego
Core Terraform best practices and compliance policies:
- Required tags enforcement (Environment, ManagedBy)
- VPC configuration (DNS support, DNS hostnames)
- EKS security (private endpoint access, encrypted volumes)
- Security group rules (no unrestricted SSH)
- ALB deletion protection for production
- CloudWatch log retention policies
- API Gateway logging requirements
- Naming convention enforcement

### cost_control.rego
Cost optimization and control policies:
- Instance type restrictions per environment
- Disk size limits for dev environments
- Node count limits
- Cost tagging requirements (CostCenter tag)
- Warnings for expensive resources

### security.rego
Security-focused policies:
- Encryption requirements (S3, EBS, RDS)
- Security group port restrictions
- IMDSv2 enforcement for EC2
- IAM role trust policy validation
- VPC flow logs recommendations
- EKS audit logging recommendations
- Public IP assignment validation

## Usage

### Prerequisites
Install OPA:
```bash
# macOS
brew install opa

# Linux
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/

# Verify installation
opa version
```

### Manual Validation

1. Generate Terraform plan in JSON format:
```bash
cd environment/dev
terraform init -backend-config=../../backend-dev.hcl
terraform plan -var-file=dev.tfvars -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
```

2. Run OPA validation:
```bash
cd ../..
./scripts/validate-with-opa.sh environment/dev/tfplan.json
```

### Testing Individual Policies

Test a specific policy file:
```bash
opa test policies/terraform.rego -v
```

Evaluate a specific rule:
```bash
opa eval --data policies/terraform.rego \
         --input environment/dev/tfplan.json \
         --format pretty \
         "data.terraform.deny"
```

## Policy Structure

Each policy file follows this structure:

```rego
package <namespace>

import future.keywords

# Deny rules - violations that must be fixed
deny[msg] {
    # conditions
    msg := "error message"
}

# Warn rules - recommendations
warn[msg] {
    # conditions
    msg := "warning message"
}
```

## CI/CD Integration

These policies are automatically enforced in the GitHub Actions workflow:
- On Pull Requests: terraform plan + OPA validation (fails on violations)
- On Main branch: terraform plan + OPA validation + terraform apply

## Adding New Policies

1. Create or edit a .rego file in this directory
2. Follow the naming convention: `package terraform.<subpackage>`
3. Use `deny[msg]` for hard failures and `warn[msg]` for warnings
4. Test your policy with sample Terraform plans
5. Update this README with policy descriptions

## Examples

### Deny Example
```rego
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.versioning
    msg := sprintf("S3 bucket '%s' must have versioning enabled", [resource.address])
}
```

### Warn Example
```rego
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.instance_type == "t2.micro"
    msg := sprintf("Consider using t3.micro instead of t2.micro for '%s'", [resource.address])
}
```

## References
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Rego Language Guide](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Terraform JSON Output Format](https://www.terraform.io/docs/internals/json-format.html)

