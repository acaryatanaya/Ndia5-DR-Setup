
variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "region" {
  description = "AWS region containing the EKS cluster and Secrets Manager secrets."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN used for Pod Identity association."
  type        = string
}

variable "secret_names" {
  description = "Names of existing client-managed Secrets Manager secrets."
  type        = set(string)

  validation {
    condition     = length(var.secret_names) > 0
    error_message = "At least one Secrets Manager secret name must be provided."
  }
}

variable "namespace" {
  description = "Kubernetes namespace for External Secrets Operator."
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "ESO controller Kubernetes service account."
  type        = string
  default     = "external-secrets"
}

variable "helm_chart_version" {
  description = "Pinned External Secrets Operator Helm chart version."
  type        = string
}

variable "kms_key_arn" {
  description = "Optional customer-managed KMS key ARN used to encrypt the secrets."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for AWS resources."
  type        = map(string)
  default     = {}
}
