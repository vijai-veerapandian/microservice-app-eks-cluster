# output.tf file

output "instance_public_ip" {
  value       = aws_instance.demo_app.public_ip
  description = "Public IP of the EC2 instance"
}

output "ec2_instance_id" {
  value       = aws_instance.demo_app.id
  description = "ID of the EC2 instance"
}

output "docker_kubectl_setup_status" {
  value       = "Docker, kubectl, and AWS CLI setup completed successfully on the EC2 instance"
  description = "Status of the Docker, kubectl, and AWS CLI setup process"
}

output "ssh_connection_command" {
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.demo_app.public_ip}"
  description = "SSH command to connect to the EC2 instance"
}

output "installed_tools" {
  value = {
    docker         = "Latest version via get.docker.com"
    docker_compose = "Latest version via apt"
    kubectl        = "Latest stable version"
    aws_cli        = "Latest AWS CLI v2"
    loki_plugin    = "grafana/loki-docker-driver:latest"
  }
  description = "List of tools installed on the EC2 instance"
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
