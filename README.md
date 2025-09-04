# Microservice App on AWS EKS

Building and deploying a Flask API with Nginx proxy to AWS EKS using Terraform. This project walks through setting up the entire infrastructure from scratch and deploying a real application.

## What We're Building

- **Flask API** - Simple REST API with health check endpoints
- **Nginx Proxy** - Routes traffic to our API
- **EKS Cluster** - Managed Kubernetes on AWS
- **Application Load Balancer** - Routes internet traffic to our app
- **EC2 Instance** - Development box with all tools pre-installed

---

## Getting Started

### Install Required Tools

First, let's get the tools we need installed on your local machine.

**AWS CLI v2:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
rm -rf awscliv2.zip aws/
```

**Terraform:**
```bash
TERRAFORM_VERSION="1.13.1"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
terraform --version
```

**kubectl:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

### AWS Account Setup

You'll need an AWS account and a user with the right permissions.

1. Go to AWS Console → IAM → Users → Create user
2. Username: `terraform-user` (or whatever you prefer)
3. Attach the `AdministratorAccess` policy (for learning - use more specific policies in production)
4. Create access key and save the credentials

Configure your AWS CLI:
```bash
aws configure
# Enter your access key, secret key, region (us-east-1), and format (json)
```

---

## Phase 1: Setting Up Infrastructure

### Step 1: Deploy Your Development EC2 Instance

We'll start by creating an EC2 instance that has all our tools pre-installed.

Create a key pair first:
```bash
aws ec2 create-key-pair --key-name my-key --region us-east-1 --query 'KeyMaterial' --output text > ~/.ssh/my-key.pem
chmod 600 ~/.ssh/my-key.pem
```

Navigate to the EC2 terraform folder and set up your config:
```bash
cd ec2-terraform-deployment/
```

Edit `terraform.tfvars`:
```hcl
aws_region = "us-east-1"
vpc_name = "demo_vpc"
vpc_cidr = "10.0.0.0/16"
instance_name = "my-dev-server"
my_ami = "ami-04b4f1a9cf54c11d0"  # Ubuntu 22.04

existing_key_pair_name = "my-key"
private_key_path = "~/.ssh/my-key.pem"

private_subnets = {
  "private_subnet_1" = 1
}
public_subnets = {
  "public_subnet_1" = 1
}
```

Deploy it:
```bash
terraform init
terraform plan
terraform apply
```

Once it's done, connect to your new EC2 instance:
```bash
ssh -i ~/.ssh/my-key.pem ubuntu@$(terraform output -raw instance_public_ip)
```

Your EC2 instance now has Docker, kubectl, AWS CLI, and Terraform ready to go!

### Step 2: Set Up EKS from EC2

Now we'll deploy our EKS cluster from the EC2 instance (this simulates how you'd do it in a real CI/CD pipeline).

**On your EC2 instance:**

Install GitHub CLI:
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```

Configure AWS (use the same credentials as before):
```bash
aws configure
```

Clone your project:
```bash
gh auth login
git clone https://github.com/your-username/your-repo.git
cd your-repo/eks-terraform-deployment/
```

Create your EKS configuration:
```bash
cat > terraform.tfvars << 'EOF'
aws_region = "us-east-1"
environment = "dev"
cluster_name = "my-eks-cluster"
cluster_version = "1.30"
vpc_cidr = "10.0.0.0/16"

node_instance_types = ["t3.medium"]
node_group_min_size = 2
node_group_max_size = 6
node_group_desired_size = 3

enable_alb_controller = true
enable_cluster_autoscaler = true
enable_metrics_server = true
enable_fluentbit = true
log_retention_days = 30
EOF
```

Deploy the EKS cluster (this takes about 15-20 minutes):
```bash
terraform init
terraform plan
terraform apply
```

Set up kubectl access:
```bash
aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster
kubectl get nodes
```

You should see something like:
```
NAME                                       STATUS   ROLES    AGE   VERSION
ip-10-0-1-234.us-east-1.compute.internal   Ready    <none>   5m    v1.30.0-eks-a737599
ip-10-0-2-345.us-east-1.compute.internal   Ready    <none>   5m    v1.30.0-eks-a737599
ip-10-0-3-456.us-east-1.compute.internal   Ready    <none>   5m    v1.30.0-eks-a737599
```

Check that all the add-ons are running:
```bash
kubectl get pods -n kube-system
```

You should see the AWS Load Balancer Controller, Cluster Autoscaler, Metrics Server, and other system pods running.

---

## Phase 2: Deploy Your Application

### Step 3: Build and Push Container Images

We'll build our Flask API and Nginx proxy images and push them to AWS ECR.

**Still on your EC2 instance:**

Create ECR repositories:
```bash
aws ecr create-repository --repository-name flask-api --region us-east-1
aws ecr create-repository --repository-name nginx-proxy --region us-east-1
```

Get your account ID and login to ECR:
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

Build and push the images:
```bash
cd ../containerization/

# Build the images
docker build -t flask-api:latest -f api-Dockerfile .
docker build -t nginx-proxy:latest -f nginx-Dockerfile .

# Tag for ECR
docker tag flask-api:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/flask-api:latest
docker tag nginx-proxy:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/nginx-proxy:latest

# Push to ECR
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/flask-api:latest
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/nginx-proxy:latest
```

### Step 4: Deploy to Kubernetes

Now let's deploy our application to the EKS cluster with an Application Load Balancer.

Create a namespace:
```bash
kubectl create namespace my-app
```

Deploy your application (you'll need to update the image URLs in your YAML files):
```bash
kubectl apply -f api-deployment.yaml -n my-app
kubectl apply -f nginx-deployment.yaml -n my-app
kubectl apply -f ingress-alb.yaml -n my-app
```

Check that everything is running:
```bash
kubectl get pods -n my-app
kubectl get services -n my-app
kubectl get ingress -n my-app
```

Get your Application Load Balancer URL:
```bash
kubectl get ingress -n my-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### Step 5: Test Your Application

Test your API:
```bash
ALB_URL=$(kubectl get ingress -n my-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
curl http://$ALB_URL/
curl http://$ALB_URL/api/v1/status
```

You should get responses from your Flask API!

---

## What You've Built

At this point, you have:

- **EKS Cluster** with auto-scaling worker nodes
- **Application Load Balancer** distributing traffic
- **Containerized Flask API** running in Kubernetes
- **Nginx proxy** handling requests
- **CloudWatch logging** collecting all your logs
- **Development EC2 instance** with all tools ready

## Cleaning Up

When you're done experimenting, clean up to avoid charges:

```bash
# From your EC2 instance, destroy the EKS cluster
cd ~/your-repo/eks-terraform-deployment/
terraform destroy

# From your local machine, destroy the EC2 instance
cd ec2-terraform-deployment/
terraform destroy

# Delete ECR repositories if you want
aws ecr delete-repository --repository-name flask-api --region us-east-1 --force
aws ecr delete-repository --repository-name nginx-proxy --region us-east-1 --force
```

## Troubleshooting

**EKS cluster not accessible?**
Make sure you ran the `aws eks update-kubeconfig` command from the same machine where you deployed the cluster.

**Pods not starting?**
Check the image URLs in your deployment files match what you pushed to ECR.

**ALB not creating?**
The AWS Load Balancer Controller takes a few minutes to create the ALB. Check the controller logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Can't connect to EC2?**
Make sure your security group allows SSH (port 22) and you're using the right key pair.

---

This project gives you hands-on experience with modern cloud-native development practices. You're deploying real infrastructure and applications the same way teams do in production!