variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources in"
  default     = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "demo_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

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

variable "instance_name" {
  type = string
}

variable "my_ami" {
  type    = string
  default = "ami-04b4f1a9cf54c11d0"
}

/*
variable "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key"
  type        = string
}
*/


variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be in the format like 't2.micro', 't3.small', etc."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    Environment = "demo"
    Project     = "terraform-docker-kubectl"
    Owner       = "devops-team"
    Terraform   = "true"
  }
}

variable "install_kubectl" {
  type        = bool
  description = "Whether to install kubectl on the EC2 instance"
  default     = true
}

variable "install_aws_cli" {
  type        = bool
  description = "Whether to install AWS CLI on the EC2 instance"
  default     = true
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root EBS volume in GB"
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 8 and 1000 GB."
  }
}
