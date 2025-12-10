# ECR (Elastic Container Registry) Module
# Creates ECR repositories with security and lifecycle policies

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repository_names)
  
  name                 = "${var.project}-${var.environment}-${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-${each.value}"
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
    }
  )
}

# ECR Repository Policy - Allow EKS nodes to pull images
resource "aws_ecr_repository_policy" "main" {
  for_each   = aws_ecr_repository.main
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodesPull"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# Lifecycle Policy - Keep last N images, expire untagged
resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = aws_ecr_repository.main
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.keep_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.keep_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than ${var.untagged_expire_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expire_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Deletion protection via resource policy (prevents accidental deletion)
resource "aws_ecr_registry_policy" "deletion_protection" {
  count = var.enable_deletion_protection ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDeleteRepository"
        Effect = "Deny"
        Principal = "*"
        Action = [
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/AllowRepositoryDelete" = "false"
          }
        }
      }
    ]
  })
}

