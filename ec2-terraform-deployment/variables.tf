# AWS Region Configuration
variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources in"
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_name" {
  type    = string
  default = "demo_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Subnet Configuration
variable "private_subnets" {
  type = map(number)
  default = {
    "private_subnet_1" = 1
  }
}

variable "public_subnets" {
  type = map(number)
  default = {
    "public_subnet_1" = 1
  }
}

# EC2 Instance Configuration
variable "instance_name" {
  type = string
}

variable "my_ami" {
  type    = string
  default = "ami-04b4f1a9cf54c11d0"
}

# =====================================================================
# NEW: Key Pair Configuration (for secure setup)
# =====================================================================
variable "existing_key_pair_name" {
  type        = string
  description = "Name of existing AWS Key Pair to use for EC2 instance"
}

variable "private_key_path" {
  type        = string
  description = "Local path to the private key file for SSH access"
}
