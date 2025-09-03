# Cluster info
output "cluster_name" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_url" {
  value = module.eks.cluster_oidc_issuer_url
}

data "aws_iam_openid_connect_provider" "oidc" {
  url = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.oidc.arn
}

# Managed node groups
output "eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}

# S3 bucket
output "logs_bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

# Add-ons
output "fluentbit_addon_name" {
  value = module.eks.cluster_addons["aws-for-fluent-bit"].addon_name
}

output "alb_controller_addon_name" {
  value = module.eks.cluster_addons["aws-load-balancer-controller"].addon_name
}

output "metrics_server_addon_name" {
  value = module.eks.cluster_addons["metrics-server"].addon_name
}
