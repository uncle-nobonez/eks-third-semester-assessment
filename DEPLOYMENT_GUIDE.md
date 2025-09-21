# InnovateMart EKS Deployment Guide
## Project Bedrock - Retail Store Application

### Architecture Overview

This deployment creates a production-grade EKS cluster on AWS with the following components:

- **VPC**: Custom VPC with public and private subnets across 3 AZs
- **EKS Cluster**: Managed Kubernetes cluster (v1.31) with 3 managed node groups
- **Application**: Microservices-based retail store with in-cluster dependencies
- **Security**: IAM roles with least privilege, read-only developer access
- **Networking**: Internet-facing Application Load Balancer

### Application Access

**Application URL**: http://k8s-default-ui-8c6cd7bbdd-f08607c24d54e805.elb.eu-north-1.amazonaws.com

The application includes:
- **UI Service**: Java-based storefront
- **Catalog Service**: Go-based product catalog with MySQL
- **Cart Service**: Java-based shopping cart with DynamoDB
- **Orders Service**: Java-based orders with PostgreSQL and RabbitMQ  
- **Checkout Service**: Node.js-based checkout with Redis

### Developer Access Configuration

#### Read-Only IAM User Credentials
- **Username**: `retail-store-eks-readonly-dev`
- **Access Key**: `AKIAWMFUPKUZMGWGBRQW`
- **Secret Key**: (Available in Terraform output - marked as sensitive)

#### Kubectl Configuration for Developers
```bash
# Configure AWS CLI with read-only credentials
aws configure set aws_access_key_id AKIAWMFUPKUZMGWGBRQW
aws configure set aws_secret_access_key <SECRET_KEY> K71WfvBp2D5liO7AjuyqionOI/SR+6c5hgfPeKk
aws configure set region eu-north-1

# Update kubeconfig
aws eks --region eu-north-1 update-kubeconfig --name retail-store

# Test access (read-only operations)
kubectl get pods
kubectl get services
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```

#### Developer Permissions
The read-only user can:
- View pods, services, deployments, and other resources
- Read pod logs
- Describe resources for troubleshooting
- List resources across all namespaces

The user **cannot**:
- Create, update, or delete resources
- Execute into pods
- Modify cluster configuration

### Infrastructure Components

#### Core Infrastructure
- **VPC**: `10.0.0.0/16` with public/private subnets
- **EKS Cluster**: `retail-store` in `eu-north-1`
- **Node Groups**: 3 managed groups with `m5.large` instances
- **Load Balancer**: AWS Load Balancer Controller for ingress

#### Security Features
- IAM roles with least privilege access
- Security groups with minimal required ports
- Encrypted EKS cluster with KMS
- Private subnets for worker nodes

### CI/CD Pipeline

The deployment uses GitHub Actions with the following workflow:
- **Feature branches**: Trigger `terraform plan` on pull requests
- **Main branch**: Trigger `terraform apply` on merge to main
- **Security**: AWS credentials stored as GitHub secrets

### Deployment Commands

#### Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd retail-store-sample-app/terraform/eks/minimal

# Initialize Terraform
terraform init

# Deploy infrastructure
terraform apply

# Configure kubectl
aws eks --region eu-north-1 update-kubeconfig --name retail-store

# Deploy application
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
```

#### Cleanup
```bash
# Remove application
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

# Destroy infrastructure
terraform destroy
```

### Monitoring and Troubleshooting

#### Check Application Status
```bash
kubectl get pods --all-namespaces
kubectl get services
kubectl logs -f deployment/ui
```

#### Common Issues
1. **LoadBalancer not accessible**: Ensure it's internet-facing
2. **Pods not starting**: Check resource limits and node capacity
3. **Database connections**: Verify service discovery and networking

### Next Steps (Bonus Objectives)

For production enhancement, consider:
1. **Managed Databases**: Replace in-cluster DBs with RDS/DynamoDB
2. **Advanced Networking**: Implement ALB Ingress with SSL/TLS
3. **Domain Setup**: Configure Route53 with custom domain
4. **Monitoring**: Add CloudWatch and Prometheus integration

---
**Project Status**: ✅ Core requirements completed
**Application Status**: ✅ Running and accessible
**Developer Access**: ✅ Configured and tested