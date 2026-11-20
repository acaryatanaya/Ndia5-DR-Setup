############################################
# EKS Inputs
############################################

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "region" {
  description = "AWS region where the EKS cluster is deployed."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the EKS cluster."
  type        = string
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN associated with the EKS cluster."
  type        = string
}

variable "oidc_issuer" {
  description = "EKS OIDC issuer URL, with or without https://."
  type        = string
}

############################################
# Controller Versions
############################################

variable "helm_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version."
  type        = string
}

variable "controller_image_tag" {
  description = "AWS Load Balancer Controller container image tag."
  type        = string
}

############################################
# Common AWS Tags
############################################

variable "tags" {
  description = "Common tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
