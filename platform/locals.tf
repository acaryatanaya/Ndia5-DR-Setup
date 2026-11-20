
############################################
# Infrastructure Outputs
############################################

locals {
  infra = data.terraform_remote_state.infra.outputs

  ##########################################
  # AWS
  ##########################################

  aws_region = local.infra.aws_region
   vpc_id     = local.infra.vpc_id

  project     = local.infra.project_name
  environment = local.infra.deployment_environment

  ##########################################
  # EKS Cluster
  ##########################################

  eks_cluster_name    = local.infra.eks_cluster_name
  eks_cluster_arn     = local.infra.eks_cluster_arn
  eks_cluster_endpoint = local.infra.eks_cluster_endpoint
  eks_cluster_version = local.infra.eks_cluster_version
  eks_cluster_ca_data  = local.infra.eks_cluster_ca_data

  ##########################################
  # OIDC / IRSA
  ##########################################

  eks_oidc_provider_arn = local.infra.eks_oidc_provider_arn
  eks_oidc_provider_url = local.infra.eks_oidc_provider_url

  ##########################################
  # Managed Node Groups
  ##########################################

  eks_node_group_names = local.infra.eks_node_group_names
  eks_node_group_arns  = local.infra.eks_node_group_arns
  eks_node_role_arn    = local.infra.eks_node_role_arn

  ##########################################
  # Common Tags
  ##########################################

  common_tags = merge(
    {
      Project     = local.project
      Environment = local.environment
      ManagedBy   = "Terraform"
      Layer       = "Platform"
    },
    var.tags
  )
}
