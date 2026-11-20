
############################################
# Terraform Configuration
############################################

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25, < 3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

############################################
# AWS Provider
############################################

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = local.common_tags
  }
}

############################################
# Kubernetes Provider
############################################

provider "kubernetes" {
  host = local.eks_cluster_endpoint

  cluster_ca_certificate = base64decode(
    local.eks_cluster_ca_data
  )

  token = data.aws_eks_cluster_auth.platform.token
}

############################################
# Helm Provider
############################################

provider "helm" {
  kubernetes {
    host = local.eks_cluster_endpoint

    cluster_ca_certificate = base64decode(
      local.eks_cluster_ca_data
    )

    token = data.aws_eks_cluster_auth.platform.token
  }
}
