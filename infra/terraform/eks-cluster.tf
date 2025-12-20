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

resource "aws_eks_cluster" "this" {
  name     = "tech-challenge-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30" # ou versão estável disponível

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
