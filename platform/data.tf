############################################
# Infrastructure Terraform Remote State
############################################

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "ndia5-dr-terraform-state"
    key    = "ndia5/dr/terraform.tfstate"
    region = "ap-south-2"
  }
}

############################################
# AWS Account Information
############################################

data "aws_caller_identity" "current" {}

############################################
# EKS Authentication
############################################

data "aws_eks_cluster_auth" "platform" {
  name = local.eks_cluster_name
}
