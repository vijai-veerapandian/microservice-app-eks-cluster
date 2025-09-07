# output.tf file

output "instance_public_ip" {
  value       = aws_instance.demo_app.public_ip
  description = "Public IP of the EC2 instance"
}

output "ec2_instance_id" {
  value       = aws_instance.demo_app.id
  description = "ID of the EC2 instance"
}

output "tools_setup_status" {
  value       = "kubectl, and AWS CLI setup completed successfully on the EC2 instance"
  description = "Status of the kubectl, and AWS CLI setup process"
}

output "ssh_connection_command" {
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.demo_app.public_ip}"
  description = "SSH command to connect to the EC2 instance"
}

output "installed_tools" {
  value = {
    kubectl = "Latest stable version"
    aws_cli = "Latest AWS CLI v2"
  }
  description = "List of tools installed on the EC2 instance"
}

output "iam_role_arn" {
  value       = aws_iam_role.ec2_eks_admin_role.arn
  description = "ARN of the IAM role attached to EC2 for EKS access"
}

output "vpc_info" {
  value = {
    vpc_id          = aws_vpc.demo_vpc.id
    vpc_cidr        = aws_vpc.demo_vpc.cidr_block
    public_subnets  = [for subnet in aws_subnet.public_subnets : subnet.id]
    private_subnets = [for subnet in aws_subnet.private_subnets : subnet.id]
  }
  description = "VPC information to use in EKS deployment"
}

output "vpc_id" {
  value       = aws_vpc.demo_vpc.id
  description = "ID of the created VPC"
}

output "security_group_id" {
  value       = aws_security_group.demo_sg.id
  description = "ID of the security group"
}

output "aws_region" {
  value       = data.aws_region.current.id
  description = "AWS region where resources are deployed"
}

output "key_pair_name" {
  value       = var.existing_key_pair_name
  description = "Name of the key pair used for EC2 instance"
}
