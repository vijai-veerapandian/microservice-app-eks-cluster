# =====================================================================
# EKS Cluster
# =====================================================================
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

  # Only official AWS managed add-ons
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

  # Use variables for node group configuration
  eks_managed_node_groups = {
    main = {
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      instance_types = var.node_instance_types

      # Use latest EKS optimized AMI
      ami_type = "AL2_x86_64"

      # Enable cluster autoscaler tags
      tags = merge(local.tags, {
        "k8s.io/cluster-autoscaler/enabled"       = "true"
        "k8s.io/cluster-autoscaler/${local.name}" = "owned"
      })
    }
  }

  tags = local.tags
}

# =====================================================================
# Wait for cluster to be ready
# =====================================================================
resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]
  create_duration = "30s"
}

# =====================================================================
# Deploy addons via kubectl/helm commands
# =====================================================================

# Configure kubectl and install AWS Load Balancer Controller
resource "null_resource" "install_alb_controller" {
  count = var.enable_alb_controller ? 1 : 0
  
  depends_on = [module.eks, time_sleep.wait_for_cluster]
  
  provisioner "local-exec" {
    command = <<-EOF
      # Configure kubectl
      aws eks update-kubeconfig --region ${var.aws_region} --name ${local.name}
      
      # Add Helm repo
      helm repo add eks https://aws.github.io/eks-charts
      helm repo update
      
      # Install AWS Load Balancer Controller
      helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${local.name} \
        --set serviceAccount.create=true \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${aws_iam_role.alb_controller[0].arn} \
        --set region=${var.aws_region} \
        --set vpcId=${module.vpc.vpc_id} \
        --version 1.7.2
    EOF
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when = destroy
    command = "helm uninstall aws-load-balancer-controller -n kube-system || true"
  }
}

# Install Cluster Autoscaler
resource "null_resource" "install_cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  
  depends_on = [module.eks, time_sleep.wait_for_cluster]
  
  provisioner "local-exec" {
    command = <<-EOF
      # Configure kubectl
      aws eks update-kubeconfig --region ${var.aws_region} --name ${local.name}
      
      # Add Helm repo
      helm repo add autoscaler https://kubernetes.github.io/autoscaler
      helm repo update
      
      # Install Cluster Autoscaler
      helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
        -n kube-system \
        --set autoDiscovery.clusterName=${local.name} \
        --set awsRegion=${var.aws_region} \
        --set serviceAccount.create=true \
        --set serviceAccount.name=cluster-autoscaler \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${aws_iam_role.cluster_autoscaler[0].arn} \
        --version 9.29.0
    EOF
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when = destroy
    command = "helm uninstall cluster-autoscaler -n kube-system || true"
  }
}

# Install Metrics Server
resource "null_resource" "install_metrics_server" {
  count = var.enable_metrics_server ? 1 : 0
  
  depends_on = [module.eks, time_sleep.wait_for_cluster]
  
  provisioner "local-exec" {
    command = <<-EOF
      # Configure kubectl
      aws eks update-kubeconfig --region ${var.aws_region} --name ${local.name}
      
      # Add Helm repo
      helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
      helm repo update
      
      # Install Metrics Server
      helm upgrade --install metrics-server metrics-server/metrics-server \
        -n kube-system \
        --version 3.12.1
    EOF
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when = destroy
    command = "helm uninstall metrics-server -n kube-system || true"
  }
}

# Install Fluent Bit
resource "null_resource" "install_fluent_bit" {
  count = var.enable_fluentbit ? 1 : 0
  
  depends_on = [
    module.eks, 
    time_sleep.wait_for_cluster,
    aws_cloudwatch_log_group.application_logs,
    aws_cloudwatch_log_group.system_logs,
    aws_cloudwatch_log_group.dataplane_logs
  ]
  
  provisioner "local-exec" {
    command = <<-EOF
      # Configure kubectl
      aws eks update-kubeconfig --region ${var.aws_region} --name ${local.name}
      
      # Create namespace
      kubectl create namespace amazon-cloudwatch --dry-run=client -o yaml | kubectl apply -f -
      
      # Add Helm repo
      helm repo add fluent https://fluent.github.io/helm-charts
      helm repo update
      
      # Install Fluent Bit
      helm upgrade --install fluent-bit fluent/fluent-bit \
        -n amazon-cloudwatch \
        --set serviceAccount.create=true \
        --set serviceAccount.name=fluent-bit \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${aws_iam_role.fluent_bit[0].arn} \
        --set config.outputs.cloudwatch.region=${var.aws_region} \
        --set config.outputs.cloudwatch.logGroupTemplate="/aws/eks/${local.name}/\$kubernetes['namespace_name']" \
        --set config.outputs.cloudwatch.logStreamTemplate="\$kubernetes['pod_name'].\$kubernetes['container_name']" \
        --set config.outputs.cloudwatch.autoCreateGroup=true \
        --set config.outputs.cloudwatch.logRetentionDays=${var.log_retention_days} \
        --version 0.46.7
    EOF
  }
