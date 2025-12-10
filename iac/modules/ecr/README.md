# ECR Module

This module creates AWS Elastic Container Registry (ECR) repositories with security best practices and lifecycle policies.

## Features

- **Multiple Repositories**: Create multiple ECR repositories from a list
- **Image Scanning**: Automatic vulnerability scanning on push
- **Encryption**: AES256 encryption enabled by default
- **Lifecycle Policies**: Automatic cleanup of old and untagged images
- **Deletion Protection**: Registry-level policy to prevent accidental deletion
- **Access Policies**: Pre-configured policies for EKS node access

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project     = "my-project"
  environment = "prod"
  
  repository_names = ["app", "worker", "api"]
  image_tag_mutability = "IMMUTABLE"
  scan_on_push = true
  
  enable_deletion_protection = true
  
  tags = {
    Owner = "DevOps"
  }
}
```

## Deletion Protection

When `enable_deletion_protection = true`, a registry policy is created that denies repository deletion unless the principal has the tag `AllowRepositoryDelete = true`.

## Lifecycle Policies

- **Tagged Images**: Keeps the last N images (default: 30)
- **Untagged Images**: Expires after N days (default: 7)

## Outputs

- `repository_urls` - Map of repository names to URLs (for docker push/pull)
- `repository_arns` - ARNs of created repositories
- `repository_names` - List of created repository names

