aws_region  = "us-east-1"
environment = "dev"

# EKS Cluster Configuration
cluster_name    = "eks-cluster01"
cluster_version = "1.30"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Node Group Configuration
node_instance_types     = ["t3.medium"]
node_group_min_size     = 1
node_group_max_size     = 4
node_group_desired_size = 2
