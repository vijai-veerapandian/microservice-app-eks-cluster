# =====================================================================
# AWS / Cluster Variables
# =====================================================================
variable "aws_region" {
  description = "AWS region to deploy the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format 'us-east-1', 'eu-west-1', etc."
  }
}

variable "environment" {
  description = "Environment tag for resources (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.cluster_version))
    error_message = "Cluster version must be in format '1.28', '1.29', etc."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

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

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

variable "node_group_desired_size" {
  description = "Desired size for the on-demand managed node group"
  type        = number

  validation {
    condition     = var.node_group_desired_size >= 1 && var.node_group_desired_size <= 100
    error_message = "Node group desired size must be between 1 and 100."
  }
}

variable "node_group_max_size" {
  description = "Maximum size for the on-demand managed node group"
  type        = number

  validation {
    condition     = var.node_group_max_size >= 1 && var.node_group_max_size <= 100
    error_message = "Node group max size must be between 1 and 100."
  }
}

variable "node_group_min_size" {
  description = "Minimum size for the on-demand managed node group"
  type        = number

  validation {
    condition     = var.node_group_min_size >= 0 && var.node_group_min_size <= 100
    error_message = "Node group min size must be between 0 and 100."
  }
}

variable "spot_node_group_desired_size" {
  description = "Desired size for the spot managed node group"
  type        = number

  validation {
    condition     = var.spot_node_group_desired_size >= 0 && var.spot_node_group_desired_size <= 100
    error_message = "Spot node group desired size must be between 0 and 100."
  }
}

variable "spot_node_group_max_size" {
  description = "Maximum size for the spot managed node group"
  type        = number

  validation {
    condition     = var.spot_node_group_max_size >= 0 && var.spot_node_group_max_size <= 100
    error_message = "Spot node group max size must be between 0 and 100."
  }
}

variable "spot_node_group_min_size" {
  description = "Minimum size for the spot managed node group"
  type        = number

  validation {
    condition     = var.spot_node_group_min_size >= 0 && var.spot_node_group_min_size <= 100
    error_message = "Spot node group min size must be between 0 and 100."
  }
}

# =====================================================================
# Add-ons Variables
# =====================================================================
variable "enable_metrics_server" {
  description = "Enable metrics-server add-on"
  type        = bool
}

variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller add-on"
  type        = bool
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler add-on"
  type        = bool
}

variable "enable_fluentbit" {
  description = "Enable Fluent Bit logging add-on"
  type        = bool
}

variable "enable_logging" {
  description = "Enable comprehensive logging setup"
  type        = bool
}

# =====================================================================
# Logging Variables
# =====================================================================
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch value."
  }
}
