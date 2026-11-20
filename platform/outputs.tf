
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

############################################
# AWS Load Balancer Controller
############################################

output "aws_load_balancer_controller_iam_role_arn" {
  description = "AWS Load Balancer Controller IRSA role ARN."
  value       = module.aws_load_balancer_controller.iam_role_arn
}

output "aws_load_balancer_controller_iam_policy_arn" {
  description = "AWS Load Balancer Controller IAM policy ARN."
  value       = module.aws_load_balancer_controller.iam_policy_arn
}

output "aws_load_balancer_controller_helm_release" {
  description = "AWS Load Balancer Controller Helm release."
  value       = module.aws_load_balancer_controller.helm_release_name
}

output "aws_load_balancer_controller_chart_version" {
  description = "Installed controller Helm chart version."
  value       = module.aws_load_balancer_controller.chart_version
}

output "aws_load_balancer_controller_image_tag" {
  description = "Installed controller image version."
  value       = module.aws_load_balancer_controller.image_tag
}

output "aws_load_balancer_controller_service_account" {
  description = "Controller Kubernetes service account."
  value       = module.aws_load_balancer_controller.service_account_name
}