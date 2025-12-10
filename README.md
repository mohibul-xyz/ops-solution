# Node.js Application on AWS EKS - DevOps Solution

A complete DevOps implementation demonstrating infrastructure as code, containerization, Kubernetes orchestration, CI/CD automation, and policy-based governance for deploying a Node.js application on AWS EKS.

## Table of Contents

- [Deliverables](#deliverables)
  - [Infrastructure as Code (Terraform)](#1-infrastructure-as-code-terraform)
  - [Kubernetes Deployment Manifests](#2-kubernetes-deployment-manifests)
  - [CI/CD Pipeline Configuration](#3-cicd-pipeline-configuration)
  - [Documentation](#4-comprehensive-documentation)
- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Deployment Steps](#deployment-steps)
- [Infrastructure as Code](#infrastructure-as-code)
- [Kubernetes Deployment](#kubernetes-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)

## Deliverables

This repository contains all required deliverables for a complete DevOps solution:

### 1. Infrastructure as Code (Terraform)
- **Location**: `iac/` directory
- **Components**:
  - Modular Terraform code for AWS VPC, EKS cluster, and ECR registries
  - Production and development environment configurations
  - Backend configuration for S3 state management with native locking
  - OPA policies for infrastructure validation and compliance
- **Terraform Plan Output**: 
  - Static plan output: [`deliverables/tfplan.json`](./deliverables/tfplan.json)
  - Live CI/CD artifacts available in GitHub Actions workflow runs:
    - [Workflow Run #20111293368](https://github.com/mohibul-xyz/ops-solution/actions/runs/20111293368) - Production deployment with OPA validation
    - Artifacts include: `tfplan-prod` (binary) and `tfplan-json-prod` (JSON format)
- **Documentation**: 
  - [`iac/README.md`](./iac/README.md) - Complete infrastructure documentation
  - [`docs/01.IAC.md`](./docs/01.IAC.md) - Detailed IaC guide

### 2. Kubernetes Deployment Manifests
- **Location**: `k8s/` directory
- **Helm Charts**: `k8s/helm/simple-api/`
  - Parameterized deployment configurations
  - Gateway API resources (GatewayClass, Gateway, HTTPRoute)
  - Service and ConfigMap definitions
  - Health check configurations (startup, liveness, readiness probes)
  - Security contexts and resource management
- **Features**:
  - Multi-environment support (dev/prod values)
  - AWS Secrets Manager integration as k8s secret
  - Rolling update strategy with zero-downtime
- **Documentation**: 
  - [`k8s/helm/simple-api/README.md`](./k8s/helm/simple-api/README.md) - Helm chart documentation
  - [`docs/02.Application.md`](./docs/02.Application.md) - Application deployment guide

### 3. CI/CD Pipeline Configuration
- **Location**: `.github/workflows/` directory
- **Pipelines**:
  - **`terraform.yml`**: Infrastructure deployment pipeline
    - Terraform plan and validation
    - OPA policy checks for production
    - Automated apply on main branch
    - AWS OIDC authentication
    - Parameter Store integration for secure tfvars
  - **`docker-build.yml`**: Application build and deploy pipeline
    - Docker multi-stage builds with caching
    - Image scanning and security checks
    - ECR push with semantic versioning
    - Helm deployment to EKS
    - Automated rollback on failure
- **Features**:
  - Automated build, test, and deployment
  - Policy-as-Code validation
  - Artifact management
  - Environment-specific workflows
  - Secure secrets handling
- **Documentation**: [`docs/03.Workflow.md`](./docs/03.Workflow.md) - Complete CI/CD guide

### 4. Comprehensive Documentation
- **Main README** (this file):
  - Architecture overview with diagrams
  - Key design decisions and assumptions
  - Technology stack and features
  - Step-by-step deployment instructions
  - Cost analysis and optimization tips
  - Security best practices
  - Troubleshooting guide
- **Structured Documentation** (`docs/` directory):
  - `01.IAC.md` - Infrastructure as Code deep dive
  - `02.Application.md` - Application architecture and deployment
  - `03.Workflow.md` - CI/CD pipeline details
  - `04.OPA.md` - Policy as Code implementation
  - `README.md` - Documentation index
- **Module Documentation**:
  - Each Terraform module includes its own README with usage examples
  - Helm charts include comprehensive values documentation

### Additional Deliverables

#### Architecture Diagrams
- Network architecture diagram showing VPC, subnets, and routing
- EKS cluster architecture with Gateway API flow
- CI/CD workflow diagrams

#### Key Assumptions
- **Cloud Provider**: AWS (ap-southeast-1 region by default)
- **Kubernetes Version**: 1.34
- **Networking**: Single NAT Gateway for cost optimization
- **State Management**: S3 with native state locking (no DynamoDB)
- **Authentication**: AWS OIDC for GitHub Actions (no long-lived credentials)
- **Secrets Management**: AWS Parameter Store for tfvars, AWS Secrets Manager for application secrets
- **Branching Strategy**: GitHub Flow (feature branches → main)

#### Deployment Instructions
Detailed step-by-step instructions are provided in the [Getting Started](#-getting-started) section below, including:
1. Prerequisites and tool setup
2. AWS credentials configuration
3. Infrastructure provisioning with Terraform
4. Application deployment with Helm
5. CI/CD pipeline setup and configuration
6. Environment-specific considerations

---


## Overview

This project demonstrates a complete end-to-end DevOps workflow for deploying a simple Node.js REST API application to AWS EKS with enterprise-grade practices:

- **Infrastructure as Code**: Fully automated AWS infrastructure provisioning using Terraform with modular design
- **Policy as Code**: Infrastructure validation and compliance using Open Policy Agent (OPA)
- **Container Orchestration**: Kubernetes deployment using Helm charts with Gateway API
- **CI/CD Automation**: GitHub Actions workflows for continuous integration and deployment
- **Multi-Environment**: Separate configurations for development and production environments
- **Security First**: AWS Secrets Manager integration, IMDSv2, encryption at rest, and security scanning
- **Cost Control**: OPA policies for cost governance and resource optimization

### Application Details

The application is a lightweight Node.js REST API built with Express that provides:
- `GET /` - Welcome endpoint returning JSON response
- `GET /health` - Health check endpoint for readiness/liveness probes

## Architecture

![Architecture Diagram](./docs/image/architecture.png)

### Infrastructure Components

The architecture consists of the following AWS services:

| Component | Description | Purpose |
|-----------|-------------|---------|
| **VPC** | Custom Virtual Private Cloud | Network isolation with multi-AZ design |
| **Public Subnets** | Internet-facing subnets | Hosts NAT Gateway and bastion host |
| **Private Subnets** | Internal subnets | Hosts EKS worker nodes for security |
| **NAT Gateway** | Network Address Translation | Enables outbound internet access for private subnets |
| **Internet Gateway** | VPC internet connection | Provides internet connectivity |
| **EKS Cluster** | Managed Kubernetes | Container orchestration platform |
| **ECR** | Elastic Container Registry | Private Docker image repository |
| **Secrets Manager** | AWS Secrets Manager | Secure storage for API keys and credentials |
| **Route53** | DNS Service | Domain name resolution |
| **ACM** | AWS Certificate Manager | SSL/TLS certificate management |
| **IAM** | Identity & Access Management | Fine-grained access control |
| **CloudWatch** | Monitoring & Logging | Centralized logging and metrics |

### Network Flow

```
Internet → Route53 → Gateway API (HTTP Route) → Service (ClusterIP) → Pods
                                                                         ↓
                                                              Private Subnets (EKS)
                                                                         ↓
                                                                   NAT Gateway
                                                                         ↓
                                                                 Internet Gateway
```

### Gateway API Architecture

Unlike traditional Ingress controllers, this solution uses **Kubernetes Gateway API** for routing:

- **GatewayClass**: Defines the load balancer implementation
- **Gateway**: Configures listeners and TLS
- **HTTPRoute**: Defines routing rules to backend services

**Benefits over Ingress**:
- Role-oriented design with clear separation of concerns
- Expressive, extensible, and role-oriented API
- Better support for advanced routing scenarios
- Growing community adoption and vendor support

## Features

### Infrastructure Management
- **Modular Terraform Design**: Reusable modules for VPC, EKS, ECR
- **Multi-Environment Support**: Separate dev and prod configurations
- **Remote State Management**: S3 backend with DynamoDB locking
- **Policy Validation**: OPA policies for compliance and cost control
- **Automated Validation**: Pre-deployment checks in CI/CD

### Application Deployment
- **Helm Charts**: Parameterized Kubernetes deployments
- **Gateway API**: Modern routing with HTTPRoute resources
- **Health Checks**: Startup, liveness, and readiness probes
- **Resource Management**: CPU/memory requests and limits
- **Security Context**: Non-root user, read-only filesystem options

### CI/CD Pipeline
- **Automated Build**: Docker image build and push to registry
- **Testing**: Automated health checks and API tests
- **Registry Caching**: Multi-layer caching for faster builds
- **Atomic Deployments**: Helm atomic upgrades with rollback
- **Secrets Integration**: AWS Secrets Manager integration

### Security
- **Secrets Management**: AWS Secrets Manager for sensitive data
- **Network Security**: Private subnets for workloads
- **IAM Roles**: OIDC-based authentication for GitHub Actions
- **Encryption**: EBS volume encryption with KMS
- **Security Policies**: OPA security policies enforcement
- **Container Security**: Non-root containers, minimal base images

## Technology Stack

### Infrastructure & Cloud
- **Cloud Provider**: AWS
- **IaC Tool**: Terraform >= 1.6.0
- **Policy Engine**: Open Policy Agent (OPA)
- **Container Registry**: GitHub Container Registry (GHCR)

### Application & Runtime
- **Language**: Node.js 18
- **Framework**: Express 4.18
- **Container**: Docker (Alpine-based)
- **Orchestration**: Kubernetes (EKS)

### CI/CD & Automation
- **CI/CD Platform**: GitHub Actions
- **Package Manager**: Helm 3
- **Authentication**: AWS OIDC for GitHub Actions

### Monitoring & Security
- **Logging**: AWS CloudWatch
- **Secrets**: AWS Secrets Manager
- **Networking**: VPC, NAT Gateway, Security Groups

## Project Structure

```
ops-solution/
├── .github/
│   └── workflows/
│       ├── ci-cd.yml              # Application CI/CD pipeline
│       └── terraform.yml          # Infrastructure CI/CD pipeline
├── docs/
│   └── image/
│       └── architecture.png       # Architecture diagram
├── iac/                           # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                   # VPC module
│   │   ├── eks/                   # EKS cluster module
│   │   └── ecr/                   # ECR repository module
│   ├── environment/
│   │   ├── dev/                   # Development environment
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── dev.tfvars
│   │   └── prod/                  # Production environment
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── prod.tfvars
│   ├── policies/                  # OPA policy files
│   │   ├── terraform.rego         # Terraform best practices
│   │   ├── security.rego          # Security policies
│   │   ├── cost_control.rego      # Cost optimization policies
│   │   └── README.md
│   ├── scripts/
│   │   └── validate-with-opa.sh   # OPA validation script
│   ├── backend-dev.hcl            # Dev backend config
│   ├── backend-prod.hcl           # Prod backend config
│   ├── README.md                  # Infrastructure documentation
│   └── SETUP.md                   # Setup guide
├── kube/                          # Kubernetes manifests
│   ├── helm/                      # Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── secret.yaml
│   │       └── _helpers.tpl
│   └── k8s/                       # Gateway API resources
│       ├── gatewayclass.yaml
│       ├── gateway.yaml
│       └── httproute.yaml
├── src/                           # Application source code
│   ├── index.js                   # Express application
│   ├── package.json               # Node.js dependencies
│   └── Dockerfile                 # Container definition
└── README.md                      # This file
```



## Infrastructure as Code

### Terraform Modules

The infrastructure is organized into reusable, composable modules:

#### VPC Module
Creates a production-ready VPC with:
- Multi-AZ architecture (2-3 availability zones)
- Public and private subnets
- NAT Gateway for private subnet internet access
- Internet Gateway for public internet connectivity
- Route tables and associations
- VPC Flow Logs for network monitoring

**Key Features**:
- Configurable CIDR blocks
- Automatic subnet calculation
- High availability by default

#### EKS Module
Deploys a managed Kubernetes cluster with:
- EKS control plane
- Managed node groups with auto-scaling
- IRSA (IAM Roles for Service Accounts)
- Cluster add-ons (VPC CNI, kube-proxy, CoreDNS)
- CloudWatch logging integration
- Private/public endpoint configuration

**Security Features**:
- Private endpoint access enabled
- Public access can be restricted in production
- IMDSv2 enforcement
- Encrypted EBS volumes
- Security group with least privilege

#### ECR Module
Provides private container registry:
- Encrypted image storage
- Lifecycle policies for image cleanup
- Cross-account access configuration
- Scan on push for vulnerability detection

### Environment Management

The project supports multiple environments with environment-specific configurations:

| Configuration | Development | Production |
|--------------|-------------|------------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Availability Zones | 2 | 3 |
| Node Count | 2 (min 1, max 4) | 3 (min 2, max 10) |
| Instance Type | t3.medium | t3.large |
| Public Access | Enabled | Disabled |
| Deletion Protection | Disabled | Enabled |

### Policy as Code

OPA (Open Policy Agent) policies enforce compliance and best practices:

#### Terraform Best Practices (`terraform.rego`)
- Required tags enforcement (Environment, ManagedBy)
- VPC DNS settings validation
- EKS security configuration checks
- Security group rule validation
- Naming convention enforcement

#### Security Policies (`security.rego`)
- Encryption at rest (EBS, S3, RDS)
- IMDSv2 requirement
- Security group port restrictions
- Public IP assignment validation
- IAM trust policy validation

#### Cost Control (`cost_control.rego`)
- Instance type restrictions per environment
- Disk size limits
- Node count limits
- Cost center tagging requirements



### State Management

Terraform state is stored remotely in S3 with:
- **Versioning**: Enabled for state history
- **Encryption**: AES-256 server-side encryption
- **Locking**: DynamoDB table prevents concurrent modifications
- **Separate States**: Independent state files per environment

## Kubernetes Deployment

### Helm Chart

The application is deployed using Helm with the following features:

#### Deployment Configuration
```yaml
replicaCount: 2                    # High availability
image:
  repository: ghcr.io/username/ops-solution
  pullPolicy: IfNotPresent
  tag: "latest"

resources:
  requests:
    cpu: 100m                      # Minimum resources
    memory: 128Mi
  limits:
    cpu: 500m                      # Maximum resources
    memory: 512Mi
```

#### Health Checks
- **Startup Probe**: Allows time for application initialization
- **Liveness Probe**: Restarts unhealthy containers
- **Readiness Probe**: Controls traffic routing to healthy pods

#### Security Context
```yaml
securityContext:
  runAsNonRoot: true               # Don't run as root
  runAsUser: 1001                  # Specific user ID
  allowPrivilegeEscalation: false  # No privilege escalation
  capabilities:
    drop:
      - ALL                        # Drop all capabilities
```

#### Secrets Management
Secrets are fetched from AWS Secrets Manager during deployment and mounted as files:
```yaml
secret:
  apiKey:
    enabled: true
    mountPath: "/etc/secrets"
```

### Gateway API Resources

#### GatewayClass
Defines the controller implementation (e.g., AWS Load Balancer Controller).

#### Gateway
Configures the load balancer with listeners, ports, and TLS settings.

#### HTTPRoute
Routes HTTP traffic to backend services with advanced routing rules:
- Path-based routing
- Header-based routing
- Query parameter matching
- Request/response modification

## CI/CD Pipeline

### Application Pipeline (`ci-cd.yml`)

The application pipeline consists of three stages:

#### 1. Build Stage
- Checks out source code
- Sets up Docker Buildx for advanced builds
- Logs into GitHub Container Registry
- Builds Docker image with multi-layer caching:
  - Registry cache for cross-runner efficiency
  - GitHub Actions cache for faster builds
- Pushes image with multiple tags:
  - Branch name (e.g., `main`, `develop`)
  - Git SHA (e.g., `main-abc1234`)
  - `latest` for default branch

**Build Optimization**:
```yaml
cache-from: |
  type=registry,ref=ghcr.io/username/ops-solution:buildcache
  type=gha
cache-to: |
  type=registry,ref=ghcr.io/username/ops-solution:buildcache,mode=max
  type=gha,mode=max
```

#### 2. Test Stage
- Pulls the built image
- Runs container with health checks
- Tests `/health` endpoint (15 attempts with retries)
- Tests `/` API endpoint with response validation
- Cleans up test containers

**Health Check Testing**:
```bash
max_attempts=15
while [ $attempt -lt $max_attempts ]; do
  if curl -f http://localhost:3000/health; then
    echo "✓ Health check passed!"
    break
  fi
  attempt=$((attempt + 1))
  sleep 2
done
```

#### 3. Deploy Stage
- Configures AWS credentials via OIDC
- Fetches secrets from AWS Secrets Manager
- Updates kubeconfig for EKS cluster
- Deploys using Helm with atomic operation:
  - Automatically rolls back on failure
  - Waits for successful rollout
  - Validates pod readiness

**Atomic Deployment**:
```bash
helm upgrade --install nodejs-simple-app . \
  --atomic \
  --cleanup-on-fail \
  --wait \
  --timeout 8m
```

### Infrastructure Pipeline (`terraform.yml`)

#### Plan Stage (All PRs & Pushes)
- Runs for both `dev` and `prod` environments in parallel
- Executes Terraform format check
- Validates Terraform configuration
- Generates execution plan
- Validates plan against OPA policies
- Uploads plan artifacts for apply stage

#### Apply Stage (Main Branch Only)
- Downloads plan artifact from previous stage
- Applies infrastructure changes automatically for `dev`
- Requires manual approval for `prod` (via GitHub Environments)

#### Policy Enforcement
All changes must pass OPA validation:
```bash
# Checks all three policy categories
./scripts/validate-with-opa.sh tfplan.json
# → terraform.rego (best practices)
# → security.rego (security requirements)
# → cost_control.rego (cost governance)
```

## Security

This project implements multiple layers of security:

### Infrastructure Security
- **Network Isolation**: Private subnets for workloads, public subnets only for ingress
- **Encryption**: EBS volumes encrypted with AWS KMS
- **IMDSv2**: Enforced on all EC2 instances (prevents SSRF attacks)
- **Security Groups**: Restrictive ingress/egress rules, no unrestricted SSH
- **VPC Flow Logs**: Network traffic monitoring and analysis

### Application Security
- **Non-Root Containers**: Runs as user ID 1001
- **Minimal Base Image**: Alpine Linux (node:18-alpine)
- **Dropped Capabilities**: All Linux capabilities dropped
- **Read-Only Root Filesystem**: Optional hardening
- **No Privilege Escalation**: Prevents container breakout

### Secrets Management
- **AWS Secrets Manager**: Centralized secret storage
- **Rotation Support**: Automatic secret rotation capabilities
- **Access Control**: IAM policies for secret access
- **Audit Logging**: CloudTrail logs all secret access
- **Secret Masking**: Secrets masked in CI/CD logs

### Access Control
- **IAM Roles**: IRSA for pod-level permissions
- **RBAC**: Kubernetes role-based access control
- **OIDC Authentication**: Passwordless CI/CD authentication
- **Principle of Least Privilege**: Minimal required permissions

### Compliance & Governance
- **Policy as Code**: OPA policies enforce security requirements
- **Automated Scanning**: Security validation in CI/CD
- **Audit Trail**: CloudTrail and CloudWatch logs
- **Compliance Checks**: Pre-deployment validation

## Monitoring & Observability

### CloudWatch Integration
- **Container Logs**: Streamed to CloudWatch Logs
- **EKS Control Plane Logs**: API server, audit, authenticator logs
- **Metrics**: CPU, memory, network, disk metrics
- **Alarms**: (To be implemented) Threshold-based alerting

### Application Observability
- **Health Endpoints**: `/health` for monitoring
- **Startup Probes**: Prevents premature traffic routing
- **Liveness Probes**: Automatic unhealthy pod restart
- **Readiness Probes**: Traffic routing to healthy pods only

### Recommended Additions
Consider adding these observability tools:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Fluentd/Fluent Bit**: Log aggregation and forwarding
- **Jaeger/X-Ray**: Distributed tracing
- **Datadog/New Relic**: Full-stack observability (commercial)

## Cost Optimization

### OPA Cost Policies
Automated cost controls through policy enforcement:

#### Instance Type Restrictions
- **Dev**: Limited to t3.small, t3.medium
- **Prod**: Allows t3.medium, t3.large, m5.large

#### Resource Limits
- **Dev**: Max 30GB EBS volumes, max 4 nodes
- **Prod**: Max 100GB EBS volumes, max 10 nodes

#### Tagging Requirements
- **CostCenter**: Required for cost allocation
- **Environment**: Required for resource tracking

### Infrastructure Optimization
- **NAT Gateway**: Single NAT Gateway in dev, multiple in prod

## Troubleshooting

### Common Issues

**Terraform State Lock**
- Ensure S3 bucket exists and has proper permissions
- Check if state locking is causing issues
- Use `terraform force-unlock` if needed

**EKS Node Group Not Ready**
- Check IAM roles and policies
- Verify subnet configurations
- Review security group rules

**OPA Policy Violations**
- Review policy error messages
- Check resource tags
- Verify instance types match allowed lists

**CI/CD Pipeline Failures**
- Check AWS credentials and OIDC configuration
- Verify GitHub secrets are properly set
- Review workflow logs for specific errors

---