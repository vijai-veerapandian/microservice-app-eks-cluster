# =====================================================================
# EKS Cluster Outputs
# =====================================================================
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_ca_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = module.eks.oidc_provider_arn
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

# =====================================================================
# Node Group Outputs
# =====================================================================
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

# =====================================================================
# VPC and Networking Outputs
# =====================================================================
output "vpc_id" {
  description = "ID of the VPC where the cluster and workers are deployed"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# =====================================================================
# AWS Region and Availability Zones
# =====================================================================
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

# =====================================================================
# S3 and Logging Outputs
# =====================================================================
output "logs_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.arn
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups created for EKS logging"
  value = var.enable_fluentbit ? {
    application = aws_cloudwatch_log_group.application_logs[0].name
    system      = aws_cloudwatch_log_group.system_logs[0].name
    dataplane   = aws_cloudwatch_log_group.dataplane_logs[0].name
  } : {}
}

# =====================================================================
# Add-on Status Outputs
# =====================================================================
output "addons_installed" {
  description = "List of addons installed on the cluster"
  value = {
    aws_load_balancer_controller = var.enable_alb_controller
    cluster_autoscaler           = var.enable_cluster_autoscaler
    metrics_server               = var.enable_metrics_server
    fluent_bit                   = var.enable_fluentbit
  }
}

# =====================================================================
# IAM Role ARNs (for reference)
# =====================================================================
output "alb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "fluent_bit_role_arn" {
  description = "ARN of the IAM role for Fluent Bit"
  value       = var.enable_fluentbit ? aws_iam_role.fluent_bit[0].arn : null
}

# =====================================================================
# Quick Setup Commands
# =====================================================================
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "cluster_status_commands" {
  description = "Commands to check cluster status"
  value = {
    nodes    = "kubectl get nodes"
    pods     = "kubectl get pods --all-namespaces"
    services = "kubectl get services --all-namespaces"
  }
}
