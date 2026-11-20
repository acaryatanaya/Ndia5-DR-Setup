
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