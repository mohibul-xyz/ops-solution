# Minimalistic EKS Module

A simplified, production-ready EKS (Elastic Kubernetes Service) module that creates the essential components for running a Kubernetes cluster on AWS.

## Features

- ✅ **Minimalistic Design**: Only essential components, no unnecessary complexity
- ✅ **Single Node Group**: One managed node group with auto-scaling
- ✅ **IAM Integration**: Automatic IAM role creation for cluster and nodes
- ✅ **Flexible Networking**: Configurable public/private API endpoint access
- ✅ **Simple Configuration**: Easy to understand and customize

## What's Included

### Core Components
- EKS Cluster (control plane)
- Managed Node Group (worker nodes)
- IAM Roles and Policies for cluster and nodes
- Proper security configurations

### What's NOT Included (Intentionally Simplified)
- ❌ Multiple node groups
- ❌ Custom security groups
- ❌ CloudWatch logging
- ❌ KMS encryption
- ❌ OIDC provider
- ❌ EKS add-ons (vpc-cni, kube-proxy, coredns, ebs-csi-driver)
- ❌ Node taints and labels
- ❌ Fargate profiles

> **Note**: These features can be added later if needed, but are omitted to keep the module simple and focused.

## Usage

### Basic Example

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "ticketbangla-dev-cluster"
  environment        = "dev"
  kubernetes_version = "1.28"
  
  subnet_ids = [
    "subnet-abc123",
    "subnet-def456",
    "subnet-ghi789"
  ]

  # Node group configuration
  desired_size   = 2
  max_size       = 4
  min_size       = 1
  instance_types = ["t3.medium"]
  disk_size      = 20

  tags = {
    Project = "TicketBangla"
    Team    = "Platform"
  }
}
```

### Environment-Specific Examples

#### Development Environment

```hcl
module "eks_dev" {
  source = "../../modules/eks"

  cluster_name       = "ticketbangla-dev"
  environment        = "dev"
  kubernetes_version = "1.28"
  
  subnet_ids = var.private_subnet_ids

  # Small cluster for dev
  desired_size   = 1
  max_size       = 2
  min_size       = 1
  instance_types = ["t3.small"]
  disk_size      = 20

  # Public access for developers
  endpoint_public_access  = true
  endpoint_private_access = true
  public_access_cidrs     = ["0.0.0.0/0"]

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

#### Production Environment

```hcl
module "eks_prod" {
  source = "../../modules/eks"

  cluster_name       = "ticketbangla-prod"
  environment        = "prod"
  kubernetes_version = "1.28"
  
  subnet_ids = var.private_subnet_ids

  # Larger cluster for production
  desired_size   = 3
  max_size       = 10
  min_size       = 2
  instance_types = ["t3.large"]
  disk_size      = 50

  # Private access only for security
  endpoint_public_access  = false
  endpoint_private_access = true

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| environment | Environment name (dev, test, staging, prod) | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster and node groups | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| desired_size | Desired number of worker nodes | `number` | `2` | no |
| max_size | Maximum number of worker nodes | `number` | `4` | no |
| min_size | Minimum number of worker nodes | `number` | `1` | no |
| instance_types | List of instance types for the node group | `list(string)` | `["t3.medium"]` | no |
| disk_size | Disk size in GB for worker nodes | `number` | `20` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The name/id of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_version | The Kubernetes server version for the cluster |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data (sensitive) |
| cluster_oidc_issuer_url | The URL on the EKS cluster OIDC Issuer |
| node_group_id | EKS node group ID |
| node_group_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| node_group_status | Status of the EKS node group |
| node_role_arn | IAM role ARN for EKS nodes |
| cluster_role_arn | IAM role ARN for EKS cluster |

## Accessing the Cluster

After creating the cluster, configure kubectl:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name ticketbangla-dev

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

## Cost Considerations

### EKS Cluster
- EKS Control Plane: ~$0.10/hour (~$73/month)

### Worker Nodes (example with t3.medium)
- t3.medium: ~$0.0416/hour (~$30/month per node)
- With 2 nodes: ~$60/month
- EBS volumes (20GB): ~$2/month per node

**Estimated Total**: ~$135/month for a minimal dev cluster

### Cost Optimization Tips

1. **Dev/Test Environments**:
   - Use smaller instance types (t3.small, t3.micro)
   - Reduce min_size to 1
   - Stop cluster during non-business hours (if possible)

2. **Production**:
   - Use Spot instances for non-critical workloads (not included in this minimal module)
   - Right-size instance types based on actual usage
   - Enable cluster autoscaler

## Security Considerations

### Network Security
- Deploy nodes in private subnets
- Restrict API endpoint access via `public_access_cidrs`
- Consider setting `endpoint_public_access = false` for production

### IAM Security
- Module creates minimal IAM roles with required permissions
- Use IRSA (IAM Roles for Service Accounts) for pod-level permissions (not included in minimal module)

### Recommendations
- Enable VPC Flow Logs
- Use AWS Security Groups to restrict traffic
- Implement Network Policies in Kubernetes
- Enable audit logging (requires CloudWatch configuration)

## Limitations of This Minimal Module

This module intentionally omits several features to maintain simplicity:

1. **No Multiple Node Groups**: Single node group only
2. **No Custom Security Groups**: Uses AWS-managed security group
3. **No Logging**: CloudWatch logging not configured
4. **No Encryption**: KMS encryption not enabled
5. **No Add-ons**: EKS add-ons must be installed separately
6. **No IRSA**: OIDC provider not configured

If you need these features, you can:
- Add them to your environment-specific configuration
- Extend this module
- Use a more comprehensive EKS module (like the official AWS EKS Terraform module)

## Extending the Module

To add features after initial deployment:

### Enable Cluster Logging
```bash
aws eks update-cluster-config \
  --name ticketbangla-dev \
  --logging '{"clusterLogging":[{"types":["api","audit"],"enabled":true}]}'
```

### Install Add-ons via kubectl
```bash
# Install EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.25"

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ticketbangla-dev
```

## Troubleshooting

### Nodes Not Joining Cluster

Check node group status:
```bash
aws eks describe-nodegroup \
  --cluster-name ticketbangla-dev \
  --nodegroup-name ticketbangla-dev-node-group
```

### Cannot Access Cluster

1. Verify your IAM permissions
2. Check public_access_cidrs includes your IP
3. Ensure security groups allow traffic

### Nodes Unhealthy

```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check node group events
aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <nodegroup>
```

## Examples

See the `/examples` directory for complete working examples:
- `examples/dev-cluster/` - Development environment
- `examples/prod-cluster/` - Production environment

## Related Documentation

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Main Project README](../../README.md)
- [Module Architecture Guide](../../docs/MODULE_ARCHITECTURE.md)

## License

This module is part of the TicketBangla Infrastructure as Code project.

---

*Last updated: November 18, 2025*

