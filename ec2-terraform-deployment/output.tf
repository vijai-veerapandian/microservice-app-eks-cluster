
output "private_key_pem" {
  value       = tls_private_key.generated.private_key_pem
  sensitive   = true
  description = "Prviate key for SSH access. Save securely"
}

output "instance_public_ip" {
  value       = aws_instance.demo_app.public_ip
  description = "Pubic_ip of the EC2 instance"
}

output "ec2_instance_id" {
  value       = aws_instance.demo_app.id
  description = "Id of the EC2 instance."
}

output "docker_status" {
  value       = "Docker setup completed successfully on the EC2 instance"
  description = "Status of the Docker setup process"
}

# Update your existing docker_status output to:
output "docker_kubectl_setup_status" {
  value       = "Docker, kubectl, and AWS CLI setup completed successfully on the EC2 instance"
  description = "Status of the Docker, kubectl, and AWS CLI setup process"
}

# New outputs to add:
output "ssh_connection_command" {
  value       = "ssh -i ec2awskey.pem ubuntu@${aws_instance.demo_app.public_ip}"
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
  value       = data.aws_region.current.name
  description = "AWS region where resources are deployed"
}
