variable "region" {
  description = "AWS region."
  type        = string
}

variable "role_name" {
  description = "IAM role name for External Secrets Operator."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN."
  type        = string
}

variable "namespace" {
  description = "ESO Kubernetes namespace."
  type        = string
  default     = "external-secrets"
}

variable "service_account" {
  description = "ESO Kubernetes service account."
  type        = string
  default     = "external-secrets"
}

variable "secret_definitions" {
  description = "AWS Secrets Manager secret names and descriptions."
  type        = map(string)

  validation {
    condition     = length(var.secret_definitions) > 0
    error_message = "At least one Secrets Manager secret must be defined."
  }
}

variable "kms_key_arn" {
  description = "Optional customer-managed KMS key ARN for Secrets Manager."
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}