output "coworking_ecr" {
  value = aws_ecr_repository.coworking.repository_url
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_version" {
  value = aws_eks_cluster.main.version
}