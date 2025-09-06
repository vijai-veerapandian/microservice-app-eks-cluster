aws_region  = "us-east-1"
aws_profile = "ec2-eks-app"
environment = "dev"

# EKS Cluster Configuration
cluster_name    = "eks-cluster01"
cluster_version = "1.30"

# Use existing VPC (get this from EC2 terraform output)
existing_vpc_id = "vpc-0334efa54af16e311" # Replace with actual VPC ID from EC2 output

# EC2 IAM Role ARN (get this from EC2 terraform output)
ec2_iam_role_arn = "arn:aws:iam::800216803559:role/ec2-eks-admin-role" # Replace with actual ARN

# Node Group Configuration
node_instance_types     = ["t3.medium"]
node_group_min_size     = 1
node_group_max_size     = 4
node_group_desired_size = 2
