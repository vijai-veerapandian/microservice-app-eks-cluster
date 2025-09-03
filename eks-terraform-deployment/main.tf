module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Enable control plane logs
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # =====================================================================
  # EKS Add-ons
  # =====================================================================
  cluster_addons = {
    metrics-server = {
      most_recent = true
    }

    aws-load-balancer-controller = {
      most_recent = true
    }

    cluster-autoscaler = {
      most_recent = true
    }

    aws-for-fluent-bit = {
      most_recent               = true
      s3_log_bucket_name         = aws_s3_bucket.logs.id
      cloudwatch_log_group_name  = "/aws/eks/${local.name}/fluentbit"
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