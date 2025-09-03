cat > test.tf << 'EOF'
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
EOF

terraform init
terraform plan
