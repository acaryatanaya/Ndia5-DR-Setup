
############################################
# AWS Account
############################################

output "aws_account_id" {
  description = "AWS account ID used by platform Terraform."
  value       = data.aws_caller_identity.current.account_id
}

############################################
# EKS Infrastructure Information
############################################

output "platform_cluster_name" {
  description = "EKS cluster name from infrastructure state."
  value       = local.eks_cluster_name
}

output "platform_cluster_arn" {
  description = "EKS cluster ARN from infrastructure state."
  value       = local.eks_cluster_arn
}

output "platform_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = local.eks_cluster_endpoint
}

output "platform_cluster_version" {
  description = "Kubernetes version."
  value       = local.eks_cluster_version
}

output "platform_node_group_names" {
  description = "EKS managed node group names."
  value       = local.eks_node_group_names
}

output "platform_aws_region" {
  description = "AWS region from infrastructure Terraform."
  value       = local.aws_region
}

############################################
# Cluster Autoscaler
############################################

output "cluster_autoscaler_iam_role_arn" {
  description = "Cluster Autoscaler IRSA role ARN."
  value       = module.cluster_autoscaler.iam_role_arn
}

output "cluster_autoscaler_helm_release" {
  description = "Cluster Autoscaler Helm release."
  value       = module.cluster_autoscaler.helm_release_name
}

output "cluster_autoscaler_chart_version" {
  description = "Cluster Autoscaler Helm chart version."
  value       = module.cluster_autoscaler.chart_version
}

output "cluster_autoscaler_image_tag" {
  description = "Cluster Autoscaler image version."
  value       = module.cluster_autoscaler.image_tag
}
