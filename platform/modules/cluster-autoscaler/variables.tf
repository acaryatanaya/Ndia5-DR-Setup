
############################################
# EKS Infrastructure Inputs
############################################

variable "cluster_name" {
  description = "Exact EKS cluster name from infrastructure Terraform."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version from infrastructure Terraform."
  type        = string
}

variable "region" {
  description = "AWS region from infrastructure Terraform."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN from infrastructure Terraform."
  type        = string
}

variable "oidc_issuer" {
  description = "EKS OIDC issuer URL from infrastructure Terraform, without https://."
  type        = string
}

############################################
# Cluster Autoscaler Versions
############################################

variable "helm_chart_version" {
  description = "Cluster Autoscaler Helm chart version."
  type        = string
}

variable "autoscaler_image_tag" {
  description = "Cluster Autoscaler container image version."
  type        = string

  validation {
    condition = startswith(
      var.autoscaler_image_tag,
      "v${var.cluster_version}."
    )

    error_message = "Cluster Autoscaler image minor version must match the EKS Kubernetes minor version."
  }
}

############################################
# Common Tags
############################################

variable "tags" {
  description = "Common AWS resource tags."
  type        = map(string)
  default     = {}
}
