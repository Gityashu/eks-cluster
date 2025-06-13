# main.tf

# Define the AWS provider
provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# VPC and Subnets for EKS
# -----------------------------------------------------------------------------
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_subnet" "eks_public_subnets" {
  count             = 2 # Create 2 public subnets
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Required for public subnets

  tags = {
    Name                                 = "${var.cluster_name}-public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Tag required for EKS
    "kubernetes.io/role/elb"             = "1"             # Tag required for public load balancers
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "eks_public_rta" {
  count          = length(aws_subnet.eks_public_subnets)
  subnet_id      = aws_subnet.eks_public_subnets[count.index].id
  route_table_id = aws_route_table.eks_public_rt.id
}

# -----------------------------------------------------------------------------
# EKS Cluster IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}


# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "example_eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = [for s in aws_subnet.eks_public_subnets : s.id]
    # Optionally, enable public and/or private access to the API server endpoint
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  tags = {
    Name = var.cluster_name
  }

  # Ensure that the EKS Cluster is created before the Node Group
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_cni_policy,
  ]
}

# -----------------------------------------------------------------------------
# EKS Node Group IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-eks-nodegroup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-eks-nodegroup-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy_eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy_ec2_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy_vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

# -----------------------------------------------------------------------------
# EKS Managed Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "example_node_group" {
  cluster_name    = aws_eks_cluster.example_eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [for s in aws_subnet.eks_public_subnets : s.id]
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that the EKS Node Group is created after the Cluster and IAM Roles
  depends_on = [
    aws_iam_role_policy_attachment.eks_nodegroup_policy_eks_worker_node,
    aws_iam_role_policy_attachment.eks_nodegroup_policy_ec2_container_registry,
    aws_iam_role_policy_attachment.eks_nodegroup_policy_vpc_cni,
  ]

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
}

# Data source to get available AZs in the specified region
data "aws_availability_zones" "available" {
  state = "available"
}
