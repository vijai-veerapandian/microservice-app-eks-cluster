data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name   = var.cluster_name
  region = var.aws_region
  azs    = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Environment = var.environment
    Project     = "EKS-Simple"
    ManagedBy   = "Terraform"
    ClusterName = var.cluster_name
  }
}
