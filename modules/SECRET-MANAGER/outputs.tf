output "external_secrets_role_arn" {
  description = "IAM role ARN assigned to ESO."
  value       = aws_iam_role.external_secrets.arn
}

output "pod_identity_association_id" {
  description = "EKS Pod Identity association ID."
  value       = aws_eks_pod_identity_association.external_secrets.association_id
}

output "secret_arns" {
  description = "Secrets Manager ARNs."
  value = {
    for name, secret in aws_secretsmanager_secret.this :
    name => secret.arn
  }
}