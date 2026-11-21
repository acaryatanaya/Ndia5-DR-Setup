output "namespace" {
  description = "Argo CD namespace."
  value       = var.namespace
}

output "helm_release_name" {
  description = "Argo CD Helm release name."
  value       = helm_release.argocd.name
}

output "helm_chart_version" {
  description = "Installed Argo CD Helm chart version."
  value       = helm_release.argocd.version
}