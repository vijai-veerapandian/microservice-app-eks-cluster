# Microservice App EKS Cluster

## Technical Stack 

Deploying containerized applications into AWS EKS using Terraform with secure infrastructure practices.

---

## Prerequisites Installation

### Step 1: Download and Install AWS CLI v2

```bash
# Download AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Extract the installer
unzip awscliv2.zip

# Run the installer
sudo ./aws/install

# Verify installation
aws --version
# Expected output: aws-cli/2.28.21 Python/3.13.7 Linux/6.15.9-arch1-1 exe/x86_64.arch

# Cleanup
rm -rf awscliv2.zip aws/
```

### Step 2: Terraform Installation 

```bash
# Set Terraform version (check for latest at https://releases.hashicorp.com/terraform/)
TERRAFORM_VERSION="1.13.1"

# Download Terraform
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Extract and install
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/terraform

# Clean up
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Verify installation
terraform --version
# Expected output: Terraform v1.13.1
```

### Step 3: kubectl Installation 

```bash
# Download the latest stable version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable and move to PATH
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

---

## AWS Setup

### Step 4: AWS IAM User Creation for Terraform

1. **Login to AWS Console**: Go to https://console.aws.amazon.com/
2. **Navigate to IAM**: Search for "IAM" in services
3. **Create User**:
   - Click "Users" → "Create user"
   - Username: `terraform-eks-user`

4. **Attach Policies** (Select "Attach existing policies directly"):
   - **For Learning/Testing**: `AdministratorAccess`
   - **For Production**: Use these specific policies:
     - `AmazonEKSClusterPolicy`
     - `AmazonEKSWorkerNodePolicy`
     - `AmazonEKS_CNI_Policy`
     - `AmazonEC2ContainerRegistryReadOnly`
     - `IAMFullAccess`
     - `AmazonVPCFullAccess`
     - `AmazonEC2FullAccess`

5. **Create Access Key**: After user creation, create access key and copy the credentials

### Step 5: Configure AWS CLI

```bash
aws configure
# AWS Access Key ID [None]: your-access-key-id
# AWS Secret Access Key [None]: your-secret-access-key
# Default region name [None]: us-west-2
# Default output format [None]: json
```

---

## Phase 1: Infrastructure Deployment

### Step 6: Deploy EKS Cluster using Terraform

#### 6.1: Navigate to EKS Terraform Directory
```bash
cd eks-terraform-deployment/
```

#### 6.2: Update Configuration
Update `terraform.tfvars` with your specific values:
```hcl
# AWS Configuration
aws_region = "us-west-2"
environment = "dev"

# EKS Cluster Configuration
cluster_name = "my-eks-cluster"
cluster_version = "1.28"

# Node Group Configuration  
node_group_min_size = 2
node_group_max_size = 6
node_group_desired_size = 3

# Add-ons Configuration
enable_alb_controller = true
enable_cluster_autoscaler = true
enable_metrics_server = true
enable_fluentbit = true
```

#### 6.3: Deploy EKS Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply -auto-approve
```

#### 6.4: Configure kubectl for EKS
```bash
# Update kubeconfig
aws eks --region us-west-2 update-kubeconfig --name my-eks-cluster

# Verify cluster access
kubectl get nodes

# Check all pods
kubectl get pods -A
```

**Expected EKS Cluster Status:**
```
NAME                                        STATUS   ROLES    AGE     VERSION
ip-10-0-13-111.us-west-2.compute.internal   Ready    <none>   8m50s   v1.30.0-eks-a737599
ip-10-0-26-54.us-west-2.compute.internal    Ready    <none>   8m29s   v1.30.0-eks-a737599
ip-10-0-36-54.us-west-2.compute.internal    Ready    <none>   8m49s   v1.30.0-eks-a737599
```

<!-- IMAGE_PLACEHOLDER: EKS Cluster Nodes Screenshot -->

### Step 7: Deploy EC2 Instance using Terraform (Secure Setup)

#### 7.1: Create AWS Key Pair (Secure Method)
```bash
# Create key pair in your target region
aws ec2 create-key-pair --key-name my-terraform-key --region us-west-2 --query 'KeyMaterial' --output text > ~/.ssh/my-terraform-key.pem

# Set proper permissions
chmod 600 ~/.ssh/my-terraform-key.pem

# Verify key pair creation
aws ec2 describe-key-pairs --key-names my-terraform-key --region us-west-2
```

#### 7.2: Navigate to EC2 Terraform Directory
```bash
cd ../ec2-terraform-deployment/
```

#### 7.3: Update EC2 Configuration
Update `terraform.tfvars` with your key pair details:
```hcl
# AWS Configuration
aws_region = "us-west-2"

# VPC Configuration
vpc_name = "demo_vpc"
vpc_cidr = "10.0.0.0/16"

# EC2 Instance Configuration
instance_name = "demo-app-server"
my_ami = "ami-04b4f1a9cf54c11d0"  # Ubuntu 22.04 LTS

# SSH Key Pair Configuration (IMPORTANT: Update these!)
existing_key_pair_name = "my-terraform-key"
private_key_path = "~/.ssh/my-terraform-key.pem"

# Subnet Configuration
private_subnets = {
  "private_subnet_1" = 1
}

public_subnets = {
  "public_subnet_1" = 1
}
```

#### 7.4: Deploy EC2 Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply -auto-approve
```

#### 7.5: Connect to EC2 Instance
```bash
# Get connection command from terraform output
terraform output ssh_connection_command

# Connect to instance
ssh -i ~/.ssh/my-terraform-key.pem ubuntu@<public-ip>

# Verify installed tools
docker --version
kubectl version --client
aws --version
```

**Expected EC2 Tools Installation:**
- ✅ Docker and Docker Compose
- ✅ kubectl (latest stable)
- ✅ AWS CLI v2
- ✅ Grafana Loki Docker plugin

<!-- IMAGE_PLACEHOLDER: EC2 Instance Tools Verification Screenshot -->

---

## Phase 2: Application Deployment

### Step 8: Build and Push Container Images to ECR

#### 8.1: Navigate to Application Directory
```bash
cd ../containerization/
```

#### 8.2: Create ECR Repositories
```bash
# Create repositories
aws ecr create-repository --repository-name flask-api --region us-west-2
aws ecr create-repository --repository-name nginx-proxy --region us-west-2

# Get login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
```

#### 8.3: Build and Push Images
```bash
# Build images
docker build -t flask-api:latest -f api-Dockerfile .
docker build -t nginx-proxy:latest -f nginx-Dockerfile .

# Tag images for ECR
docker tag flask-api:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/flask-api:latest
docker tag nginx-proxy:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/nginx-proxy:latest

# Push images
docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/flask-api:latest
docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/nginx-proxy:latest
```

### Step 9: Deploy Application to EKS with ALB

#### 9.1: Deploy Application Manifests
```bash
# Apply namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
EOF

# Deploy API and Nginx services
kubectl apply -f api-deployment.yaml
kubectl apply -f nginx-deployment.yaml

# Deploy ALB Ingress
kubectl apply -f ingress-alb.yaml
```

#### 9.2: Verify Application Deployment
```bash
# Check application pods
kubectl get pods -n my-app

# Check services
kubectl get services -n my-app

# Check ALB Ingress
kubectl get ingress -n my-app

# Get ALB URL
kubectl get ingress app-ingress -n my-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

<!-- IMAGE_PLACEHOLDER: Application Pods Running Screenshot -->
<!-- IMAGE_PLACEHOLDER: ALB Ingress Details Screenshot -->

---

## Verification and Testing

### Step 10: Test Application Access

#### 10.1: Test via ALB (Application Load Balancer)
```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress app-ingress -n my-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test application endpoints
curl http://$ALB_URL/
curl http://$ALB_URL/api/v1/status
```

#### 10.2: Test via EC2 Instance
```bash
# SSH to EC2 instance
ssh -i ~/.ssh/my-terraform-key.pem ubuntu@<ec2-public-ip>

# Test Docker containers
docker ps

# Test kubectl access to EKS
kubectl get nodes
kubectl get pods -n my-app
```

<!-- IMAGE_PLACEHOLDER: Application Response Screenshots -->

---

## Architecture Overview

### Current Infrastructure:
- ✅ **EKS Cluster** with managed node groups
- ✅ **Application Load Balancer** for traffic distribution
- ✅ **VPC** with public/private subnets
- ✅ **EC2 Development Instance** with Docker and kubectl
- ✅ **ECR** for container image registry
- ✅ **CloudWatch Logging** with Fluent Bit
- ✅ **Auto-scaling** with Cluster Autoscaler

### Security Features:
- ✅ **No private keys in Git** (using existing AWS key pairs)
- ✅ **IRSA** (IAM Roles for Service Accounts) for secure addon permissions
- ✅ **Encrypted EBS volumes**
- ✅ **VPC network isolation**
- ✅ **Security groups** with minimal required access

<!-- IMAGE_PLACEHOLDER: Architecture Diagram -->

---

## Cleanup

### To destroy all resources:
```bash
# Destroy EKS cluster
cd eks-terraform-deployment/
terraform destroy -auto-approve

# Destroy EC2 infrastructure  
cd ../ec2-terraform-deployment/
terraform destroy -auto-approve

# Delete ECR repositories (optional)
aws ecr delete-repository --repository-name flask-api --region us-east-1 --force
aws ecr delete-repository --repository-name nginx-proxy --region us-east-1 --force
```

---

## Troubleshooting

### Common Issues:

1. **Key Pair Not Found**: Ensure key pair exists in the correct region
2. **kubectl Access Denied**: Run `aws eks update-kubeconfig` command
3. **ALB Not Creating**: Check AWS Load Balancer Controller logs
4. **Pods Not Starting**: Check ECR image URLs and permissions

### Useful Commands:
```bash
# Check EKS cluster status
aws eks describe-cluster --name my-eks-cluster --region us-west-2

# Check ALB Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check application logs
kubectl logs -n my-app deployment/api-deployment
kubectl logs -n my-app deployment/nginx-deployment
```