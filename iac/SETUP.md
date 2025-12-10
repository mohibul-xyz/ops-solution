# Quick Setup Guide

This guide will help you set up and deploy the infrastructure from scratch.

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] OPA (Open Policy Agent) installed
- [ ] GitHub repository with Actions enabled

## Step 1: AWS Backend Setup (One-time)

Run these commands to create the S3 backend for state management:

```bash
# Set variables
export AWS_REGION="ap-southeast-1"
export BUCKET_NAME="ops-solution-tearrform-state"
export DYNAMODB_TABLE="ops-solution-terraform-locks"

# Create S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION
```

## Step 2: GitHub Actions Setup

### Create IAM Roles for GitHub OIDC

```bash
# Create trust policy for GitHub OIDC
cat > github-oidc-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<GITHUB_ORG>/<GITHUB_REPO>:*"
        }
      }
    }
  ]
}
EOF

# Create OIDC provider (if not exists)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create IAM role for dev/staging
aws iam create-role \
  --role-name github-actions-terraform-dev \
  --assume-role-policy-document file://github-oidc-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name github-actions-terraform-dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create IAM role for production
aws iam create-role \
  --role-name github-actions-terraform-prod \
  --assume-role-policy-document file://github-oidc-trust-policy.json

aws iam attach-role-policy \
  --role-name github-actions-terraform-prod \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- **AWS_ROLE_ARN**: `arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform-dev`
- **AWS_PROD_ROLE_ARN**: `arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform-prod`

## Step 3: Local Development Setup

### Initialize Dev Environment

```bash
cd iac/environment/dev

# Initialize with backend
terraform init -backend-config=../../backend-dev.hcl

# Review the plan
terraform plan -var-file=dev.tfvars

# Generate JSON plan for OPA
terraform plan -var-file=dev.tfvars -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Validate with OPA
../../scripts/validate-with-opa.sh tfplan.json

# Apply if validation passes
terraform apply -var-file=dev.tfvars
```

### Initialize Prod Environment

```bash
cd iac/environment/prod

# Initialize with backend
terraform init -backend-config=../../backend-prod.hcl

# Review the plan
terraform plan -var-file=prod.tfvars

# Generate JSON plan for OPA
terraform plan -var-file=prod.tfvars -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Validate with OPA
../../scripts/validate-with-opa.sh tfplan.json

# Apply if validation passes (manual approval recommended for prod)
terraform apply -var-file=prod.tfvars
```

## Step 4: Verify Deployment

### Check Infrastructure

```bash
# Get outputs
terraform output

# Test API Gateway
API_URL=$(terraform output -raw api_gateway_invoke_url)
curl $API_URL/health

# Configure kubectl for EKS
aws eks update-kubeconfig \
  --name $(terraform output -raw eks_cluster_id) \
  --region ap-southeast-1

# Check cluster
kubectl get nodes
kubectl get pods -A
```

## Step 5: Deploy Application to EKS

Once infrastructure is ready, deploy your application:

```bash
# Example deployment
kubectl create deployment app \
  --image=<your-app-image> \
  --port=80

# Create service pointing to ALB target group
kubectl expose deployment app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=80

# Or use AWS Load Balancer Controller
kubectl apply -f k8s/ingress.yaml
```

## Step 6: Configure ALB Target Group

Register your EKS service with the ALB target group:

1. Get the target group ARN:
   ```bash
   terraform output -raw target_group_arn
   ```

2. Use AWS Load Balancer Controller or manual registration:
   ```bash
   # Install AWS Load Balancer Controller
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     --set clusterName=$(terraform output -raw eks_cluster_id) \
     -n kube-system
   ```

3. Create TargetGroupBinding:
   ```yaml
   apiVersion: elbv2.k8s.aws/v1beta1
   kind: TargetGroupBinding
   metadata:
     name: app-tgb
   spec:
     serviceRef:
       name: app
       port: 80
     targetGroupARN: <target-group-arn>
   ```

## Continuous Deployment

After initial setup, use the GitHub Actions workflow:

1. **Development**: Push to `main` branch automatically deploys to dev
2. **Production**: Use manual workflow dispatch for prod deployment

## Cleanup

To destroy the infrastructure:

```bash
# Dev environment
cd environment/dev
terraform destroy -var-file=dev.tfvars

# Prod environment
cd environment/prod
terraform destroy -var-file=prod.tfvars

# Clean up backend (optional - only if you want to remove everything)
aws s3 rb s3://ops-solution-tearrform-state --force
aws dynamodb delete-table --table-name ops-solution-terraform-locks
```

## Troubleshooting

### Common Issues

1. **Backend bucket doesn't exist**
   - Run Step 1 to create the S3 bucket and DynamoDB table

2. **AWS credentials not configured**
   - Run `aws configure` and enter your credentials

3. **OPA validation fails**
   - Review the policy violations in the output
   - Fix the issues in your Terraform code
   - Re-run the plan and validation

4. **State lock timeout**
   - Check if another operation is in progress
   - Force unlock if necessary: `terraform force-unlock <lock-id>`

5. **GitHub Actions fails**
   - Verify AWS_ROLE_ARN secrets are set correctly
   - Check IAM role trust policy allows GitHub OIDC
   - Review CloudWatch logs for detailed errors

## Next Steps

1. ✅ Infrastructure deployed
2. Deploy your application to EKS
3. Configure monitoring (CloudWatch, Prometheus)
4. Set up log aggregation (CloudWatch Logs, ELK)
5. Configure alerts and notifications
6. Document application-specific deployment procedures

## Support

For issues or questions:
- Review the main README.md
- Check the policies/README.md for OPA policy details
- Consult Terraform and AWS documentation

