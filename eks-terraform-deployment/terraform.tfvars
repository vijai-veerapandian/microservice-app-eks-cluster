
# AWS Configuration

aws_region  = "us-east-1" # Change to your preferred region
environment = "dev"       # dev, staging, prod


# EKS Cluster Configuration

cluster_name    = "eks-cluster01"
cluster_version = "1.30"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"


# Node Group Configuration
# Instance types for worker nodes
node_instance_types = ["t3.medium", "t3.large"]

# Node group sizing
node_group_min_size     = 2
node_group_max_size     = 6
node_group_desired_size = 3

# Spot instances (optional - currently not used in main.tf)
spot_node_group_min_size     = 1
spot_node_group_max_size     = 10
spot_node_group_desired_size = 2

# Add-ons Configuration (Enable/Disable)
enable_alb_controller     = true # AWS Load Balancer Controller
enable_cluster_autoscaler = true # Cluster Autoscaler
enable_metrics_server     = true # Metrics Server
enable_fluentbit          = true # Fluent Bit for logging

# Logging Configuration
log_retention_days = 30

# Optional: Additional logging settings
enable_logging = true
