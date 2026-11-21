variable "namespace" {
  description = "Kubernetes namespace for Argo CD."
  type        = string
  default     = "argocd"
}

variable "helm_chart_version" {
  description = "Pinned Argo CD Helm chart version."
  type        = string
}

variable "tags" {
  description = "Tags for AWS resources, if any."
  type        = map(string)
  default     = {}
}

variable "server_hostname" {
  description = "External hostname for Argo CD GUI."
  type        = string
}