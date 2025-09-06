# Use existing VPC data instead of creating new one
data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["private_subnet_*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["public_subnet_*"]
  }
}

# Create additional private subnets for EKS in different AZs
resource "aws_subnet" "eks_private_subnets" {
  count             = 2
  vpc_id            = var.existing_vpc_id
  cidr_block        = cidrsubnet(data.aws_vpc.existing.cidr_block, 8, count.index + 10)
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name                                  = "eks-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  })
}

# Get the existing private route table to associate new subnets
data "aws_route_tables" "private" {
  vpc_id = var.existing_vpc_id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Associate new EKS subnets with the existing private route table
resource "aws_route_table_association" "eks_private" {
  count          = length(aws_subnet.eks_private_subnets)
  subnet_id      = aws_subnet.eks_private_subnets[count.index].id
  route_table_id = data.aws_route_tables.private.ids[0]
}
