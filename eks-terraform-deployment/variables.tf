# =====================================================================
# AWS / Cluster Variables
# =====================================================================
variable "aws_region" {
  description = "AWS region to deploy the EKS cluster"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment tag for resources (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# =====================================================================
# Managed Node Group Variables
# =====================================================================
variable "node_instance_types" {
  description = "EC2 instance types for on-demand node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_group_desired_size" {
  description = "Desired size for the on-demand managed node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum size for the on-demand managed node group"
  type        = number
  default     = 6
}

variable "node_group_min_size" {
  description = "Minimum size for the on-demand managed node group"
  type        = number
  default     = 2
}

variable "spot_node_group_desired_size" {
  description = "Desired size for the spot managed node group"
  type        = number
  default     = 3
}

variable "spot_node_group_max_size" {
  description = "Maximum size for the spot managed node group"
  type        = number
  default     = 10
}

variable "spot_node_group_min_size" {
  description = "Minimum size for the spot managed node group"
  type        = number
  default     = 2
}

# =====================================================================
# Add-ons Variables
# =====================================================================
variable "enable_metrics_server" {
  description = "Enable metrics-server add-on"
  type        = bool
  default     = true
}

variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller add-on"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler add-on"
  type        = bool
  default     = true
}

variable "enable_fluentbit" {
  description = "Enable Fluent Bit logging add-on"
  type        = bool
  default     = true
}
