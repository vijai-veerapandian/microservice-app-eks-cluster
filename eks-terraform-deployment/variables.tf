variable "aws_region" {
  description = "AWS region to deploy the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment tag for resources (dev, staging, prod)"
  type        = string
  default     = "dev"

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
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "existing_vpc_id" {
  description = "ID of the existing VPC to use for EKS"
  type        = string
}

variable "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role for EKS access"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired size for the managed node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum size for the managed node group"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum size for the managed node group"
  type        = number
  default     = 1
}
