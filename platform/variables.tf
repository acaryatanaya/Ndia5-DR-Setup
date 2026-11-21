
############################################
# Common Platform Tags
############################################

variable "tags" {
  description = "Additional tags applied to platform AWS resources."
  type        = map(string)
  default     = {}
}

############################################
# Cluster Autoscaler Versions
############################################

variable "cluster_autoscaler_chart_version" {
  description = "Helm chart version for Cluster Autoscaler."
  type        = string
}

variable "cluster_autoscaler_image_tag" {
  description = "Cluster Autoscaler container image version."
  type        = string
}

############################################
# AWS Load Balancer Controller Versions
############################################

variable "aws_load_balancer_controller_chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller."
  type        = string
}

variable "aws_load_balancer_controller_image_tag" {
  description = "Container image version for AWS Load Balancer Controller."
  type        = string
}


############################################
# External Secrets Operator
############################################

variable "external_secrets_chart_version" {
  description = "Pinned Helm chart version for External Secrets Operator."
  type        = string
}

variable "external_secrets_secret_names" {
  description = "Existing client-managed Secrets Manager secret names."
  type        = set(string)
}

variable "external_secrets_kms_key_arn" {
  description = "Optional customer-managed KMS key ARN for Secrets Manager."
  type        = string
  default     = null
}

############################################
# Argo CD
############################################

variable "argocd_chart_version" {
  description = "Pinned Helm chart version for Argo CD."
  type        = string
}

variable "argocd_server_hostname" {
  description = "External DNS hostname for Argo CD."
  type        = string
}

variable "argocd_image_updater_chart_version" {
  description = "Pinned Argo CD Image Updater Helm chart version."
  type        = string
  default     = "1.3.2"
}