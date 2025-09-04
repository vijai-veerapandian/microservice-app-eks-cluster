# =====================================================================
# EKS Cluster
# =====================================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Basic cluster configuration
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true

  # Essential AWS add-ons only
  cluster_addons = {
    coredns = {
      addon_version = "v1.11.1-eksbuild.9"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.2"
    }
    vpc-cni = {
      addon_version = "v1.18.1-eksbuild.1"
    }
    aws-load-balancer-controller = {
      addon_version = "v2.7.2-eksbuild.1"
    }
    cluster-autoscaler = {
      addon_version = "v1.30.0-eksbuild.1"
    }
    aws-for-fluent-bit = {
      addon_version = "v0.1.40-eksbuild.1"
    }
    metrics-server = {
      # Note: metrics-server is not an official AWS managed addon.
      # The EKS module deploys it via a Helm chart.
      # We can leave this as is, or specify a chart version if needed.
    }
  }

  # Single node group for simplicity
  eks_managed_node_groups = {
    main = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.medium"]

      # Cluster autoscaler tags
      tags = {
        "k8s.io/cluster-autoscaler/enabled"       = "true"
        "k8s.io/cluster-autoscaler/${local.name}" = "owned"
      }
    }
  }

  tags = local.tags
}
