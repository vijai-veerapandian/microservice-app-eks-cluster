# 1 Retrieve the list of AZs in the current AWS region
# 2 Define the VPC
# 3 Define the Security group
# 4 Deploy the private subnets
# 5 Deploy the public subnets
# 6 Define the internet Gateway
# 7 Define the nat gateway
# 8 Define Route table for public subnet
# 9 Define Route table for private subnet
# 10 Associate the Route table with the public and private subnet
# 11 Associate IAM Role with EC2 instance also with EKS later
# 12 Deploy AWS EC2 instance

# 1 Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

# 2 Define the VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# 3 Define the Security group
resource "aws_security_group" "demo_sg" {
  name        = "demo_security_group"
  description = "demo security group"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all inbound traffic
    description = "Allow all inbound traffic for testing"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
    description = "Allow all outbound traffic"
  }

  tags = {
    Name      = "demo_security_group"
    Terraform = "true"
  }
}

# 4 Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

# 5 Deploy the public subnets
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

# 6 Define Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_igw"
  }
}

# 7 Define nat gateway
resource "aws_eip" "nat_gateway_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "demo_igw_eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_subnet.public_subnets]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id

  tags = {
    Name = "demo_nat_gateway"
  }
}

# 8 Define Route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name      = "demo_public_route_table"
    Terraform = "true"
  }
}

# 9 Define Route table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_private_route_table"
    Terraform = "true"
  }
}

# 10 Associate the Route table with the public and private subnet

resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
}

# 11 Associate IAM Role with EC2 instance also with EKS later

resource "aws_iam_role" "ec2_eks_admin_role" {
  name = "ec2-eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EC2-EKS-Admin-Role"
    Environment = "dev"
  }
}

# Custom policy for EKS administration
resource "aws_iam_policy" "eks_admin_policy" {
  name        = "EKS-Admin-Policy"
  description = "Policy for EC2 to manage EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "iam:ListRoles",
          "iam:ListInstanceProfiles",
          "iam:PassRole",
          "iam:GetRole",
          "iam:CreateServiceLinkedRole",
          "iam:CreatePolicy",             # NEW
          "iam:GetPolicy",                # NEW
          "iam:AttachRolePolicy",         # NEW
          "iam:DetachRolePolicy",         # NEW
          "iam:CreateRole",               # NEW
          "iam:TagRole",                  # NEW
          "iam:ListAttachedRolePolicies", # NEW
          "logs:*",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "cloudformation:*",
          "kms:DescribeKey",
          "kms:ListKeys",
          "ecr:*",                 # NEW
          "elasticloadbalancing:*" # NEW
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the custom policy to the role
resource "aws_iam_role_policy_attachment" "eks_admin_policy_attachment" {
  role       = aws_iam_role.ec2_eks_admin_role.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_eks_profile" {
  name = "ec2-eks-admin-profile"
  role = aws_iam_role.ec2_eks_admin_role.name
}

# 12 Deploy AWS EC2 instance

resource "aws_instance" "demo_app" {
  ami                    = var.my_ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnets["public_subnet_1"].id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  key_name               = var.existing_key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_eks_profile.name

  tags = {
    Terraform = "true"
    Name      = var.instance_name
  }
}
# Docker and kubectl setup using remote-exec provisioner
resource "null_resource" "docker_kubectl_setup" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.demo_app.public_ip
      user        = "ubuntu"
      private_key = file(var.private_key_path)
    }

    inline = [
      "set -e", # Stop on the first error
      "set -x", # Print each command before execution

      # Update system
      "sudo apt update",

      # Install Docker
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install docker-compose -y",
      "docker --version",
      "docker-compose --version",
      "sleep 10",

      # Install Loki Docker plugin
      "sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions",
      "sudo docker plugin ls",
      "sleep 5",

      # Install kubectl
      "echo 'Installing kubectl...'",
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "rm kubectl", # Clean up the downloaded file

      # Verify kubectl installation
      "kubectl version --client",

      # Install AWS CLI
      "echo 'Installing AWS CLI...'",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "sudo apt-get install unzip -y",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm -rf awscliv2.zip aws/", # Clean up
      "aws --version",

      # Install Terraform 
      "echo 'Installing Terraform...'",
      "TERRAFORM_VERSION='1.13.1'",
      "wget https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip",
      "unzip terraform_$${TERRAFORM_VERSION}_linux_amd64.zip",
      "sudo mv terraform /usr/local/bin/",
      "sudo chmod +x /usr/local/bin/terraform",
      "rm terraform_$${TERRAFORM_VERSION}_linux_amd64.zip",
      "terraform --version",

      # Create kubectl config directory for ubuntu user
      "mkdir -p /home/ubuntu/.kube",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.kube",

      "echo 'Docker and kubectl installation completed successfully!'",
      "echo 'Docker version:' && docker --version",
      "echo 'kubectl version:' && kubectl version --client",
      "echo 'AWS CLI version:' && aws --version",

      # Install Helm
      "sudo apt-get install curl -y",
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      "helm version",

      # Install gh
      "sudo apt-get install gh -y"
    ]
  }

  depends_on = [aws_instance.demo_app]
}
