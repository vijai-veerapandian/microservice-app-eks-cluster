module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  enable_irsa = true

  # Enable control plane logs
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # =====================================================================
  # EKS Add-ons (only AWS-managed ones)
  # =====================================================================
  cluster_addons = {
    metrics-server = {
      most_recent = true
    }

    aws-for-fluent-bit = {
      most_recent               = true
      s3_log_bucket_name        = aws_s3_bucket.logs.id
      cloudwatch_log_group_name = "/aws/eks/${local.name}/fluentbit"
    }
  }

  # =====================================================================
  # Managed Node Groups (Production-style)
  # =====================================================================
  eks_managed_node_groups = {
    on_demand = {
      desired_size   = 3
      max_size       = 6
      min_size       = 2
      instance_types = var.node_instance_types
      disk_size      = 50
      disk_type      = "gp3"
      labels = {
        workload = "system"
        type     = "on-demand"
      }
    }

    spot = {
      desired_size   = 3
      max_size       = 10
      min_size       = 2
      capacity_type  = "SPOT"
      instance_types = ["m5.large", "m5a.large", "m5d.large", "m4.large"]
      disk_size      = 50
      labels = {
        workload = "app"
        type     = "spot"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  tags = local.tags
}

# =====================================================================
# Helm releases for Cluster Autoscaler and AWS Load Balancer Controller
# =====================================================================

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

# Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.29.0" # Adjust if newer version available

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }
}

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1" # Adjust if newer version available

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }
}
