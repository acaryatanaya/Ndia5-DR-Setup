output "iam_role_arn" {
  description = "IAM role ARN used by Argo CD Image Updater."
  value       = aws_iam_role.image_updater.arn
}

output "service_account_name" {
  description = "Kubernetes service account used by Image Updater."
  value       = var.service_account_name
}

output "pod_identity_association_id" {
  description = "EKS Pod Identity association ID."
  value       = aws_eks_pod_identity_association.image_updater.association_id
}

output "helm_release_name" {
  description = "Argo CD Image Updater Helm release name."
  value       = helm_release.image_updater.name
}
