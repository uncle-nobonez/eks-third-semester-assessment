# IAM User for Development Team - Read-Only EKS Access
resource "aws_iam_user" "eks_readonly_dev" {
  name = "${var.environment_name}-eks-readonly-dev-uncle"
  path = "/"
}

resource "aws_iam_access_key" "eks_readonly_dev" {
  user = aws_iam_user.eks_readonly_dev.name
}

# IAM Policy for EKS Read-Only Access
resource "aws_iam_policy" "eks_readonly" {
  count       = var.existing_iam_policy_arn == "" ? 1 : 0
  name        = "${var.environment_name}-eks-readonly"
  description = "Read-only access to EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

locals {
  eks_readonly_policy_arn = length(aws_iam_policy.eks_readonly) > 0 ? aws_iam_policy.eks_readonly[0].arn : var.existing_iam_policy_arn
}

resource "aws_iam_user_policy_attachment" "eks_readonly_dev" {
  user       = aws_iam_user.eks_readonly_dev.name
  policy_arn = local.eks_readonly_policy_arn
}

# Kubernetes RBAC for read-only access
resource "kubernetes_cluster_role" "readonly" {
  metadata {
    name = "eks-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "readonly" {
  metadata {
    name = "eks-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.readonly.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = aws_iam_user.eks_readonly_dev.name
    api_group = "rbac.authorization.k8s.io"
  }
}