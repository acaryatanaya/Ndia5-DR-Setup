
############################################
# Cluster Autoscaler
############################################

module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"

  cluster_name    = local.eks_cluster_name
  cluster_version = local.eks_cluster_version
  region          = local.aws_region

  oidc_provider_arn = local.eks_oidc_provider_arn
  oidc_issuer       = local.eks_oidc_provider_url

  helm_chart_version = var.cluster_autoscaler_chart_version
  autoscaler_image_tag = var.cluster_autoscaler_image_tag

  tags = local.common_tags
}

############################################
# AWS Load Balancer Controller
############################################

module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"

  cluster_name = local.eks_cluster_name
  region       = local.aws_region
  vpc_id       = local.vpc_id

  oidc_provider_arn = local.eks_oidc_provider_arn
  oidc_issuer       = local.eks_oidc_provider_url

  helm_chart_version = var.aws_load_balancer_controller_chart_version
  controller_image_tag = var.aws_load_balancer_controller_image_tag

  tags = local.common_tags
}


############################################
# External Secrets Operator
############################################

module "external_secrets" {
  source = "./modules/external-secrets"

  cluster_name = local.eks_cluster_name
  region       = local.aws_region

  namespace            = "external-secrets"
  service_account_name = "external-secrets"

  helm_chart_version = var.external_secrets_chart_version

  secret_names = var.external_secrets_secret_names

  # Keep null for AWS-managed Secrets Manager encryption.
  kms_key_arn = var.external_secrets_kms_key_arn

  tags = local.common_tags
}


############################################
# Argo CD
############################################

module "argo_cd" {
  source = "./modules/argo-cd"

  namespace          = "argocd"
  helm_chart_version = var.argocd_chart_version
  server_hostname    = var.argocd_server_hostname

  tags = local.common_tags
}