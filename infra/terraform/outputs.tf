output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = "us-east-1"
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.this.name
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.comments_db.endpoint
}

output "rds_db_name" {
  description = "Database Name"
  value       = aws_db_instance.comments_db.db_name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.api_repo.repository_url
}
