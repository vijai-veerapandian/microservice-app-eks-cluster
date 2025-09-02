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

```
➜  microservice-app-eks-cluster git:(main) wget https://releases.hashicorp.com/terraform/1.13.1/terraform_1.13.1_linux_amd64.zip
--2025-09-02 11:50:15--  https://releases.hashicorp.com/terraform/1.13.1/terraform_1.13.1_linux_amd64.zip
Loaded CA certificate '/etc/ssl/certs/ca-certificates.crt'
Resolving releases.hashicorp.com (releases.hashicorp.com)... 3.164.92.12, 3.164.92.66, 3.164.92.93, ...
Connecting to releases.hashicorp.com (releases.hashicorp.com)|3.164.92.12|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 30635389 (29M) [application/zip]
Saving to: ‘terraform_1.13.1_linux_amd64.zip’

terraform_1.13.1_linux_amd64.zip                   100%[==============================================================================================================>]  29.22M  97.2MB/s    in 0.3s    

2025-09-02 11:50:16 (97.2 MB/s) - ‘terraform_1.13.1_linux_amd64.zip’ saved [30635389/30635389]
```


# Extract and install
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/terraform

# Clean up
rm terraform_1.13.1_linux_amd64.zip

# Verify installation
```
➜  microservice-app-eks-cluster git:(main) ✗ terraform --version
Terraform v1.13.1
on linux_amd64
```