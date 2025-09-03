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
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-load-balancer-controller = {
      most_recent = true
    }
    cluster-autoscaler = {
      most_recent = true
    }
    aws-for-fluent-bit = {
      most_recent = true
    }
    metrics-server = {
      most_recent = true
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
