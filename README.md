# microservice-app-eks-cluster
Deploying container application into AWS EKS using EKS blueprint

# Download AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Extract the installer
unzip awscliv2.zip

# Run the installer
sudo ./aws/install


```
➜  microservice-app-eks-cluster git:(main) ✗ pwd
/home/vijai/Documents/backup-2-arch/microservice-app-eks-cluster
```

```
➜  aws git:(main) ✗ sudo ./install
You can now run: /usr/local/bin/aws --version
➜  aws git:(main) ✗ aws --version
aws-cli/2.28.21 Python/3.13.7 Linux/6.15.9-arch1-1 exe/x86_64.arch
```

cleanup

```
rm -rf awscliv2.zip aws/
```


#### Install Terraform 
# Download Terraform (check for latest version at https://releases.hashicorp.com/terraform/)
TERRAFORM_VERSION="1.13.1"
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
# Should output: Terraform v1.6.6