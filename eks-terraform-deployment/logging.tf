# =====================================================================
# CloudWatch Log Groups for Application Logs
# =====================================================================

# Log group for application logs
resource "aws_cloudwatch_log_group" "application_logs" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/${local.name}/application"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# Log group for system logs (kube-system namespace)
resource "aws_cloudwatch_log_group" "system_logs" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/${local.name}/system"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# Log group for dataplane logs (worker nodes)
resource "aws_cloudwatch_log_group" "dataplane_logs" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/${local.name}/dataplane"
  retention_in_days = 14 # Shorter retention for node logs
  tags              = local.tags
}
