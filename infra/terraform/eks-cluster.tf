resource "aws_iam_role" "eks_cluster_role" {
  name = "tech-challenge-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "tech-challenge-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_kms_key" "eks_secrets" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "tech-challenge-eks-secrets-key"
  }
}

resource "aws_eks_cluster" "this" {
  # checkov:skip=CKV_AWS_39:Cluster precisa ser acessível publicamente para CI/CD (GitHub Actions)
  # checkov:skip=CKV_AWS_38:Cluster precisa ser acessível publicamente para CI/CD (GitHub Actions)
  name     = "tech-challenge-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30" # ou versão estável disponível

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
    resources = ["secrets"]
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet.id,
      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_b.id,
    ]
    security_group_ids = [aws_security_group.app_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    Name = "tech-challenge-eks"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}
