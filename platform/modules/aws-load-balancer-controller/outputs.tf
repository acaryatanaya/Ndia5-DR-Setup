############################################
# AWS Load Balancer Controller Outputs
############################################

output "iam_role_arn" {
  description = "IRSA IAM role ARN for AWS Load Balancer Controller."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "iam_policy_arn" {
  description = "IAM policy ARN attached to the controller role."
  value       = aws_iam_policy.aws_load_balancer_controller.arn
}

output "service_account_name" {
  description = "Kubernetes service account used by the controller."
  value       = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
}

output "helm_release_name" {
  description = "AWS Load Balancer Controller Helm release name."
  value       = helm_release.aws_load_balancer_controller.name
}

output "namespace" {
  description = "Namespace where the controller is installed."
  value       = helm_release.aws_load_balancer_controller.namespace
}

output "chart_version" {
  description = "Installed AWS Load Balancer Controller Helm chart version."
  value       = helm_release.aws_load_balancer_controller.version
}

output "image_tag" {
  description = "AWS Load Balancer Controller container image tag."
  value       = var.controller_image_tag
}
