module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Basic cluster configuration
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true

  # Enable EKS control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Essential AWS managed add-ons only
  cluster_addons = {
    coredns = {
      addon_version     = "v1.11.3-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.30.0-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.18.1-eksbuild.3"
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      addon_version     = "v1.2.0-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Simple node group configuration
  eks_managed_node_groups = {
    main = {
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      instance_types = var.node_instance_types

      # Use latest EKS optimized AMI
      ami_type = "AL2_x86_64"
    }
  }

  tags = local.tags
}
