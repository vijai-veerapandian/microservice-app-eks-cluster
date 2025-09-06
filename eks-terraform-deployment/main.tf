module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  # Use existing VPC
  vpc_id     = var.existing_vpc_id
  subnet_ids = concat(data.aws_subnets.private.ids, aws_subnet.eks_private_subnets[*].id)

  # Enable both private and public access
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Restrict in production

  enable_irsa = true

  # Enable EKS control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Essential AWS managed add-ons
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

  # Node group configuration
  eks_managed_node_groups = {
    main = {
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      instance_types = var.node_instance_types

      ami_type = "AL2_x86_64"

      # Ensure nodes are distributed across multiple AZs
      subnet_ids = concat(data.aws_subnets.private.ids, aws_subnet.eks_private_subnets[*].id)
    }
  }

  # Grant your EC2 IAM role admin access to the cluster
  access_entries = {
    ec2_admin = {
      principal_arn = var.ec2_iam_role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.tags
}
