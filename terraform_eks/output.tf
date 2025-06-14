  # output.tf

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.example_eks_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API."
  value       = aws_eks_cluster.example_eks_cluster.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.example_eks_cluster.arn
}

output "eks_kubeconfig_command" {
  description = "Command to update your kubeconfig to connect to the cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.example_eks_cluster.name}"
}