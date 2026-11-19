output "cluster_name" {
  description = "Cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "Cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "Kubernetes version."
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA data for kubeconfig."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group (attached to the control plane and the nodes)."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_role_arn" {
  description = "Control plane IAM role ARN."
  value       = aws_iam_role.cluster.arn
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN (for IRSA)."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL without https://."
  value       = local.oidc_provider_url_bare
}

output "kms_key_arn" {
  description = "KMS key ARN used for secrets encryption (null if none)."
  value       = local.kms_arn
}

output "node_group_names" {
  description = "EKS managed node group names."
  value       = [for k, v in aws_eks_node_group.this : v.node_group_name]
}

output "node_group_arns" {
  description = "EKS managed node group ARNs."
  value       = [for k, v in aws_eks_node_group.this : v.arn]
}

output "node_role_arn" {
  description = "Worker node IAM role ARN."
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Worker node IAM role name."
  value       = aws_iam_role.node.name
}

output "addon_arns" {
  description = "ARNs of the installed add-ons, keyed by name."
  value       = { for k, v in aws_eks_addon.this : k => v.arn }
}

output "irsa_role_arns" {
  description = "IRSA role ARNs created for add-ons, keyed by add-on name."
  value       = { for k, v in aws_iam_role.irsa : k => v.arn }
}

output "cluster_additional_security_group_id" {
  description = "Security group created by this module for the control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group created by this module for the worker nodes."
  value       = aws_security_group.node.id
}