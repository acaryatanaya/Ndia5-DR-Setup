variable "cluster_name" {
  description = "Name of the DR EKS cluster."
  type        = string
}

variable "region" {
  description = "AWS region hosting the DR EKS cluster and replicated ECR repositories."
  type        = string
}

variable "account_id" {
  description = "AWS account ID containing the replicated ECR repositories."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where Argo CD Image Updater runs."
  type        = string
  default     = "argocd"
}

variable "service_account_name" {
  description = "Service account used by Argo CD Image Updater."
  type        = string
  default     = "argocd-image-updater"
}

variable "helm_chart_version" {
  description = "Pinned Argo CD Image Updater Helm chart version."
  type        = string
  default     = "1.3.2"
}

variable "ecr_repository_names" {
  description = "ECR repositories that Image Updater is allowed to inspect."
  type        = set(string)

  default = [
    "ndia5/frontend-prod"
  ]
}

variable "tags" {
  description = "Tags applied to AWS IAM resources."
  type        = map(string)
  default     = {}
}