#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "terra-cluster" {
  name = "eshop-mgmt-eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "terra-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.terra-cluster.name
}

resource "aws_iam_role_policy_attachment" "terra-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.terra-cluster.name
}

resource "aws_security_group" "terra-cluster" {
  name        = "eshop-mgmt-terraform-eks-cluster-sg"
  description = "Cluster communication sg with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eshop-mgmt-terraform-eks-sg"
  }
}

resource "aws_security_group_rule" "terra-cluster-ingress-workstation-https" {
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.terra-cluster.id
  type              = "ingress"
}

resource "aws_eks_cluster" "mgmt" {
  name     = "eshop-mgmt-${var.cluster_name}"
  version  = 1.24
  role_arn = aws_iam_role.terra-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.terra-cluster.id]
    subnet_ids         = [var.subnet_id1, var.subnet_id2]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access = var.endpoint_public_access
    public_access_cidrs = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  depends_on = [
    aws_iam_role_policy_attachment.terra-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.terra-cluster-AmazonEKSVPCResourceController,
  ]
}


