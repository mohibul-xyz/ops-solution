# Infrastructure as Code (IaC)

This directory contains Terraform configurations for managing AWS infrastructure across multiple environments (dev and prod).

## 🏗️ Architecture

The infrastructure consists of:

- **VPC**: Custom VPC with public and private subnets across multiple availability zones
- **EKS**: Managed Kubernetes cluster with properly configured node groups
- **ALB**: Internal Application Load Balancer for routing traffic to EKS workloads
- **API Gateway**: HTTP API with VPC Link integration to ALB
  - Routes: `GET /` and `GET /health`
  - Private integration via VPC Link to internal ALB

```
Internet → API Gateway → VPC Link → ALB (Private) → EKS Cluster
                                                    ↓
                                            Private Subnets
                                                    ↓
                                              NAT Gateway
                                                    ↓
                                            Internet Gateway
```

## 📁 Directory Structure

```
iac/
├── backend-dev.hcl           # S3 backend config for dev
├── backend-prod.hcl          # S3 backend config for prod
├── example.tfvars            # Example variables file
├── main.tf                   # Root module (not used, env-specific)
├── variables.tf              # Root variables
├── outputs.tf                # Root outputs
├── modules/
│   ├── vpc/                  # VPC module
│   ├── eks/                  # EKS cluster module
│   ├── alb/                  # Application Load Balancer module
│   └── api-gateway/          # API Gateway with VPC Link module
├── environment/
│   ├── dev/
│   │   ├── main.tf           # Dev environment configuration
│   │   ├── variables.tf      # Dev variables
│   │   ├── outputs.tf        # Dev outputs
│   │   └── dev.tfvars        # Dev variable values
│   └── prod/
│       ├── main.tf           # Prod environment configuration
│       ├── variables.tf      # Prod variables
│       ├── outputs.tf        # Prod outputs
│       └── prod.tfvars       # Prod variable values
├── policies/
│   ├── terraform.rego        # Terraform best practices policies
│   ├── cost_control.rego     # Cost optimization policies
│   ├── security.rego         # Security policies
│   └── README.md             # Policy documentation
└── scripts/
    └── validate-with-opa.sh  # OPA validation script
```

## 🚀 Getting Started

### Prerequisites

1. **Terraform** (>= 1.0)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **AWS CLI** configured with appropriate credentials
   ```bash
   aws configure
   ```

3. **OPA** (Open Policy Agent)
   ```bash
   # macOS
   brew install opa
   
   # Linux
   curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
   chmod +x opa
   sudo mv opa /usr/local/bin/
   ```

4. **S3 Backend Setup**
   
   Create the S3 bucket and DynamoDB table for state management:
   ```bash
   # Create S3 bucket
   aws s3api create-bucket \
     --bucket ops-solution-tearrform-state \
     --region ap-southeast-1 \
     --create-bucket-configuration LocationConstraint=ap-southeast-1
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket ops-solution-tearrform-state \
     --versioning-configuration Status=Enabled
   
   # Enable encryption
   aws s3api put-bucket-encryption \
     --bucket ops-solution-tearrform-state \
     --server-side-encryption-configuration \
     '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name ops-solution-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region ap-southeast-1
   ```

### Deployment

#### Development Environment

1. Navigate to dev environment:
   ```bash
   cd environment/dev
   ```

2. Initialize Terraform with backend:
   ```bash
   terraform init -backend-config=../../backend-dev.hcl
   ```

3. Review the plan:
   ```bash
   terraform plan -var-file=dev.tfvars
   ```

4. Generate plan for OPA validation:
   ```bash
   terraform plan -var-file=dev.tfvars -out=tfplan.binary
   terraform show -json tfplan.binary > tfplan.json
   ```

5. Run OPA policy validation:
   ```bash
   ../../scripts/validate-with-opa.sh tfplan.json
   ```

6. Apply the configuration:
   ```bash
   terraform apply -var-file=dev.tfvars
   ```

#### Production Environment

1. Navigate to prod environment:
   ```bash
   cd environment/prod
   ```

2. Initialize Terraform with backend:
   ```bash
   terraform init -backend-config=../../backend-prod.hcl
   ```

3. Follow steps 3-6 from dev environment (use `prod.tfvars`)

## 🔄 CI/CD Pipeline

The infrastructure uses GitHub Actions for automated deployment with OPA policy validation.

### Workflow Triggers

- **Pull Request**: Runs `terraform plan` and OPA validation for both environments
- **Push to main**: Automatically deploys to dev environment
- **Manual Dispatch**: Allows manual deployment to prod (requires approval)

### Required Secrets

Configure these secrets in GitHub repository settings:

- `AWS_ROLE_ARN`: IAM role ARN for dev/staging deployments
- `AWS_PROD_ROLE_ARN`: IAM role ARN for production deployments

### Workflow File

Located at `.github/workflows/terraform.yml`

### Policy Enforcement

All infrastructure changes are validated against OPA policies:
- **Terraform Best Practices**: Tagging, naming conventions, resource configuration
- **Cost Control**: Instance types, disk sizes, node counts
- **Security**: Encryption, security groups, IAM policies

Violations will cause the pipeline to fail.

## 📝 Configuration

### Environment Variables

Key variables to customize per environment:

| Variable | Dev Default | Prod Default | Description |
|----------|-------------|--------------|-------------|
| `vpc_cidr` | 10.0.0.0/16 | 10.1.0.0/16 | VPC CIDR block |
| `availability_zones` | 2 AZs | 3 AZs | Number of AZs |
| `node_group_desired_size` | 2 | 3 | EKS node count |
| `node_instance_types` | t3.medium | t3.large | Instance types |
| `endpoint_public_access` | true | false | EKS public access |
| `alb_enable_deletion_protection` | false | true | ALB deletion protection |

### Customization

1. Copy `example.tfvars` to your environment directory
2. Modify values according to your requirements
3. Ensure compliance with OPA policies

## 🔒 Security Considerations

- **EKS**: Private endpoint access enabled, public access restricted in prod
- **ALB**: Internal load balancer in private subnets
- **API Gateway**: VPC Link for private integration
- **Encryption**: EBS volumes encrypted with KMS
- **IMDSv2**: Required for all EC2 instances
- **Security Groups**: Restricted ingress rules

## 📊 Outputs

After successful deployment, the following outputs are available:

```bash
terraform output
```

Key outputs:
- `api_gateway_invoke_url`: API Gateway endpoint URL
- `eks_cluster_endpoint`: EKS cluster endpoint
- `alb_dns_name`: Internal ALB DNS name
- `vpc_id`: VPC identifier

## 🧪 Testing

### Format Check
```bash
terraform fmt -check -recursive
```

### Validation
```bash
terraform validate
```

### Policy Testing
```bash
# Test all policies
opa test policies/ -v

# Test specific policy
opa eval --data policies/terraform.rego \
         --input environment/dev/tfplan.json \
         --format pretty \
         "data.terraform.deny"
```

## 🛠️ Troubleshooting

### Backend Initialization Issues
```bash
# Remove local state and re-initialize
rm -rf .terraform
terraform init -backend-config=../../backend-<env>.hcl -reconfigure
```

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>

# Or remove the lock from DynamoDB
aws dynamodb delete-item \
  --table-name ops-solution-terraform-locks \
  --key '{"LockID":{"S":"<lock-id>"}}'
```

### Plan Failures
```bash
# Refresh state
terraform refresh -var-file=<env>.tfvars

# Detailed logging
TF_LOG=DEBUG terraform plan -var-file=<env>.tfvars
```

## 📚 Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [API Gateway VPC Link](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vpc-links.html)

## 🤝 Contributing

1. Create a feature branch
2. Make changes to IaC
3. Run format and validation
4. Test with OPA policies
5. Create pull request
6. Review terraform plan output
7. Merge after approval

## 📄 License

This infrastructure code is part of the ops-solution project.

