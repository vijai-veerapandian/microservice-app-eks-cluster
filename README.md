#### microservice-app-eks-cluster

#### Technical stack 

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


#### Step: Terraform Installation 

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

#### Step: kubectl installation 

# Download the latest stable version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable and move to PATH
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
# Should output client version information

#### Step: AWS IAM User creation for terraform

Login to AWS Console: Go to https://console.aws.amazon.com/
Navigate to IAM: Search for "IAM" in services
Create User:

Click "Users" → "Create user"
Username: terraform-eks-user

Attach Policies directly no need to create group for the user

Select "Attach existing policies directly"
Search and attach these policies:

AdministratorAccess (for simplicity)
Or for production, use these specific policies:

AmazonEKSClusterPolicy
AmazonEKSWorkerNodePolicy
AmazonEKS_CNI_Policy
AmazonEC2ContainerRegistryReadOnly
IAMFullAccess
AmazonVPCFullAccess
AmazonEC2FullAccess

once created review it and then select and create accesskey and copy the key and secrets.

update the local aws cli to use the access and secret key.

```
➜  microservice-app-eks-cluster git:(main) aws configure
AWS Access Key ID [None]: xxxxx
AWS Secret Access Key [None]: xxxxx
Default region name [None]: us-west-2
Default output format [None]: json
```

#### Step: Execute terraform cmds

```
terraform init 
terraform plan 
terraform apply -auto-approve
```

#### Step: Validate terraform output

```
 eks-terraform-deployment git:(main) ✗ terraform output cluster_arn                                             

"arn:aws:eks:us-west-2:800216803559:cluster/eks-blueprint-cluster"
```

```
➜  eks-terraform-deployment git:(main) ✗ aws eks --region us-west-2 update-kubeconfig --name eks-blueprint-cluster
Added new context arn:aws:eks:us-west-2:800216803559:cluster/eks-blueprint-cluster to /home/vijai/.kube/config
➜  eks-terraform-deployment git:(main) ✗ 
```

```
➜  eks-terraform-deployment git:(main) ✗ kubectl get nodes
NAME                                      STATUS   ROLES    AGE   VERSION
ip-10-0-47-4.us-west-2.compute.internal   Ready    <none>   21m   v1.28.15-eks-3abbec1
ip-10-0-9-39.us-west-2.compute.internal   Ready    <none>   23m   v1.28.15-eks-3abbec1
➜  eks-terraform-deployment git:(main) ✗ kubectl get pods -A
NAMESPACE           NAME                                                        READY   STATUS    RESTARTS   AGE
amazon-cloudwatch   aws-cloudwatch-metrics-hs5tk                                1/1     Running   0          21m
amazon-cloudwatch   aws-cloudwatch-metrics-ngtsz                                1/1     Running   0          22m
cert-manager        cert-manager-55657857dd-k52zr                               1/1     Running   0          25m
cert-manager        cert-manager-cainjector-7b5b5d4786-f2nm4                    1/1     Running   0          25m
cert-manager        cert-manager-webhook-55fb5c9c88-kpkxk                       1/1     Running   0          25m
kube-system         aws-for-fluent-bit-8b45f                                    1/1     Running   0          22m
kube-system         aws-for-fluent-bit-w257t                                    1/1     Running   0          21m
kube-system         aws-load-balancer-controller-67d4dbcf74-5klnv               1/1     Running   0          25m
kube-system         aws-load-balancer-controller-67d4dbcf74-mk86v               1/1     Running   0          25m
kube-system         aws-node-bg6zh                                              2/2     Running   0          20m
kube-system         aws-node-gbkc4                                              2/2     Running   0          20m
kube-system         cluster-autoscaler-aws-cluster-autoscaler-9b6d669dc-xkkvs   1/1     Running   0          25m
kube-system         coredns-5f4bcd6c95-rnfvb                                    1/1     Running   0          20m
kube-system         coredns-5f4bcd6c95-wm6xh                                    1/1     Running   0          20m
kube-system         ebs-csi-controller-5d86447476-gjcmr                         6/6     Running   0          20m
kube-system         ebs-csi-controller-5d86447476-nd7g7                         6/6     Running   0          20m
kube-system         ebs-csi-node-54dhx                                          3/3     Running   0          20m
kube-system         ebs-csi-node-vclln                                          3/3     Running   0          20m
kube-system         kube-proxy-k9npj                                            1/1     Running   0          20m
kube-system         kube-proxy-xkdxp                                            1/1     Running   0          20m
kube-system         metrics-server-6d449868fd-prpwc                             1/1     Running   0          25m
```
