# =====================================================================
# AWS / Cluster Variables
# =====================================================================
variable "aws_region" {
  description = "AWS region to deploy the EKS cluster"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format 'us-east-1', 'eu-west-1', etc."
  }
}

variable "environment" {
  description = "Environment tag for resources (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster01"
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

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
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

variable "enable_logging" {
  description = "Enable logging with Fluent Bit"
  type        = bool
  default     = false
}

# =====================================================================
# Logging Variables
# =====================================================================
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch value."
  }
}
