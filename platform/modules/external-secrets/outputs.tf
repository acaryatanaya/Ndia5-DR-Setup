output "iam_role_arn" {
  description = "IAM role ARN associated with ESO through EKS Pod Identity."
  value       = aws_iam_role.external_secrets.arn
}

output "iam_policy_arn" {
  description = "IAM policy ARN granting read-only access to approved secrets."
  value       = aws_iam_policy.external_secrets.arn
}

output "pod_identity_association_id" {
  description = "EKS Pod Identity association ID."
  value       = aws_eks_pod_identity_association.external_secrets.association_id
}

output "helm_release_name" {
  description = "ESO Helm release name."
  value       = helm_release.external_secrets.name
}

output "secret_arns" {
  description = "ARNs of existing Secrets Manager secrets discovered by Terraform."
  value       = local.secret_arns
}
