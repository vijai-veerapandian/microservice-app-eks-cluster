# =====================================================================
# Basic Configuration (matches your existing variables.tf)
# =====================================================================

# AWS Configuration
aws_region  = "us-east-1"
aws_profile = "default"

# VPC Configuration
vpc_name = "demo_vpc"
vpc_cidr = "10.0.0.0/16"

# Subnet Configuration
private_subnets = {
  "private_subnet_1" = 1
}

public_subnets = {
  "public_subnet_1" = 1
}

# EC2 Instance Configuration
instance_name = "demo1-server"
my_ami        = "ami-04b4f1a9cf54c11d0" # Ubuntu 22.04 LTS in us-east-1

# =====================================================================
# NEW: Key Pair Configuration (add these to your variables.tf)
# =====================================================================
existing_key_pair_name = "demo-server-ec2awskey"            # Replace with your actual key pair name
private_key_path       = "~/.ssh/demo-server-ec2awskey.pem" # Replace with your actual private key path
