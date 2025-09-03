# main.tf
#### DATA SOURCES & LOCALS

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name   = var.cluster_name
  region = var.aws_region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Environment = var.environment
    Project     = "EKS-Blueprint"
    ManagedBy   = "Terraform"
    ClusterName = var.cluster_name
  }
}

#### EKS BLUEPRINTS

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  # Networking
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnets
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Security
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Logging
  cluster_enabled_log_types = ["audit", "api", "authenticator", "controllerManager", "scheduler"]

  # Grant cluster access to the IAM entity that is running Terraform
  access_entries = {
    # The user/role that creates the cluster
    cluster_creator = {
      principal_arn = data.aws_caller_identity.current.arn
      policy_associations = {
        cluster_admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    # On-Demand Node Group
    mg_5 = {
      node_group_name = "${local.name}-managed-ondemand"
      instance_types  = var.node_instance_types
      ami_type        = "AL2_x86_64"
      capacity_type   = "ON_DEMAND"

      subnet_ids = module.vpc.private_subnets

      desired_size = var.node_group_desired_size
      max_size     = var.node_group_max_size
      min_size     = var.node_group_min_size

      disk_size = 50
      disk_type = "gp3"

      force_update_version = false

      k8s_taints = []

      k8s_labels = {
        Environment   = var.environment
        NodeGroup     = "managed-ondemand"
        NodeGroupType = "managed"
      }

      additional_tags = {
        ExtraTag = "EKS managed node group"
        Name     = "${local.name}-managed-ondemand"
      }

      create_launch_template = true
      launch_template_os     = "amazonlinux2eks"

      # Node group update configuration
      update_config = {
        max_unavailable_percentage = 25
      }
    }

    # Spot Instance Node Group
    mg_spot = {
      node_group_name = "${local.name}-managed-spot"
      instance_types  = ["m5.large", "m5a.large", "m5d.large", "m4.large"]
      ami_type        = "AL2_x86_64"
      capacity_type   = "SPOT"

      subnet_ids = module.vpc.private_subnets

      desired_size = 1
      max_size     = 3
      min_size     = 0

      disk_size = 50
      disk_type = "gp3"

      k8s_taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      k8s_labels = {
        Environment   = var.environment
        NodeGroup     = "managed-spot"
        NodeGroupType = "spot"
      }

      additional_tags = {
        ExtraTag = "EKS managed spot node group"
        Name     = "${local.name}-managed-spot"
      }

      create_launch_template = true
      launch_template_os     = "amazonlinux2eks"

      update_config = {
        max_unavailable_percentage = 25
      }
    }
  }

  tags = local.tags
}


####  KMS KEY FOR EKS CLUSTER ENCRYPTION 

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.tags, {
    Name = "${local.name}-eks-encryption-key"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

#### IRSA for EBS CSI Driver

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

#### EKS BLUEPRINTS ADD-ONS

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.13" # Using a more specific version constraint

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Essential Add-ons
  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true
  enable_cert_manager                 = true

  # Additional Add-ons (set to true to enable)
  enable_aws_efs_csi_driver     = false
  enable_aws_fsx_csi_driver     = false
  enable_aws_cloudwatch_metrics = true
  enable_aws_for_fluentbit      = true
  enable_argocd                 = false
  enable_argo_rollouts          = false
  enable_argo_workflows         = false
  enable_ingress_nginx          = false
  enable_karpenter              = false

  # AWS Load Balancer Controller
  aws_load_balancer_controller = {
    chart_version = "1.6.2"
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"
    values = [
      yamlencode({
        clusterName = module.eks.cluster_name
        serviceAccount = {
          create = true
          name   = "aws-load-balancer-controller"
        }
        region = local.region
        vpcId  = module.vpc.vpc_id
      })
    ]
  }

  # Cluster Autoscaler
  cluster_autoscaler = {
    chart_version = "9.29.0"
    repository    = "https://kubernetes.github.io/autoscaler"
    namespace     = "kube-system"
    values = [
      yamlencode({
        autoDiscovery = {
          clusterName = module.eks.cluster_name
        }
        awsRegion = local.region
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
        }
      })
    ]
  }

  # Metrics Server
  metrics_server = {
    chart_version = "3.11.0"
    repository    = "https://kubernetes-sigs.github.io/metrics-server/"
    namespace     = "kube-system"
    values = [
      yamlencode({
        args = [
          "--cert-dir=/tmp",
          "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
          "--kubelet-use-node-status-port",
          "--metric-resolution=15s"
        ]
      })
    ]
  }

  # Cert Manager
  cert_manager = {
    chart_version = "1.13.1"
    repository    = "https://charts.jetstack.io"
    namespace     = "cert-manager"
    values = [
      yamlencode({
        installCRDs = true
        serviceAccount = {
          create = true
          name   = "cert-manager"
        }
      })
    ]
  }

  # Configure Fluent Bit to send logs to CloudWatch (default) and an S3 bucket.
  # The addon handles creating the necessary IAM role and service account.
  aws_for_fluentbit = {
    # Note: This assumes you have a resource 'aws_s3_bucket "logs"' defined elsewhere in your configuration.
    s3_log_bucket_name = aws_s3_bucket.logs.id
  }

  tags = local.tags

  depends_on = [
    # This explicit dependency is required to ensure the LBC's webhook is ready before other addons are installed.
    module.eks_blueprints_addons.aws_load_balancer_controller_helm_release
  ]
}
