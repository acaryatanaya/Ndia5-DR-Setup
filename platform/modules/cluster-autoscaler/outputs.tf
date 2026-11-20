
############################################
# Cluster Autoscaler Outputs
############################################

output "iam_role_arn" {
  description = "Cluster Autoscaler IRSA IAM role ARN."
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "iam_policy_arn" {
  description = "Cluster Autoscaler IAM policy ARN."
  value       = aws_iam_policy.cluster_autoscaler.arn
}

output "helm_release_name" {
  description = "Cluster Autoscaler Helm release name."
  value       = helm_release.cluster_autoscaler.name
}

output "namespace" {
  description = "Namespace where Cluster Autoscaler is deployed."
  value       = helm_release.cluster_autoscaler.namespace
}

output "chart_version" {
  description = "Installed Cluster Autoscaler Helm chart version."
  value       = helm_release.cluster_autoscaler.version
}

output "image_tag" {
  description = "Cluster Autoscaler container image tag."
  value       = var.autoscaler_image_tag
}
